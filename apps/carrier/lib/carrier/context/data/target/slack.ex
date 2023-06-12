defmodule Carrier.Data.Target.Slack do
  @behaviour Carrier.Data.Target

  use Carrier.Integrations
  alias Carrier.External.SlackAPI

  @impl true
  def validate_conn(:slack, %{bot_token: bot_token}, _opts) do
    case SlackAPI.test_api(bot_token) do
      :ok -> :ok
      {:error, _} -> {:error, :invalid_conn_info}
    end
  end

  @impl true
  def header_to_messages(%DataTarget{service_name: :slack}, header) do
    messages = header |> header_to_message()

    {:ok, messages}
  end

  @impl true
  def threads_to_messages(%DataTarget{service_name: :slack}, threads) do
    messages =
      threads
      |> Enum.map(fn blocks ->
        blocks |> Enum.map(&block_to_message/1)
      end)
      |> Enum.intersperse(SlackAPI.Block.build_divider_block())
      |> List.flatten()
      |> List.wrap()

    {:ok, messages}
  end

  @impl true
  def send_messages(
        %DataTarget{service_name: :slack} = data_target,
        header_messages,
        messages,
        %{channel_id: channel_id}
      ) do
    credentials = data_target |> DataTarget.to_credentials()

    with :ok <-
           (header_messages ++ messages)
           |> List.flatten()
           |> then(&post_message(channel_id, &1, credentials)) do
      :ok
    end
  end

  defp header_to_message(%{name: name, text: text}) do
    formatted_text = SlackAPI.Format.html_to_mrkdwn(text)

    [
      [
        SlackAPI.Block.build_text_block("*#{name}*")
      ],
      unless Blankable.blank?(formatted_text) do
        [
          SlackAPI.Block.build_text_block(formatted_text, "mrkdwn", false)
        ]
      end
    ]
    |> Enum.reject(&is_nil(&1))
  end

  defp block_to_message(%{type: :text, text: text, style: style}) do
    text =
      case style do
        :normal -> text
        :bold -> "*#{text}*"
      end

    SlackAPI.Block.build_text_block(text)
  end

  defp block_to_message(%{type: :link, text: text, url: url}) do
    SlackAPI.Block.build_link_block(text, url)
  end

  defp block_to_message(%{
         type: :image,
         title: title,
         image_url: image_url,
         alt_text: alt_text
       }) do
    SlackAPI.Block.build_image_block(image_url, title, alt_text)
  end

  defp block_to_message(%{type: :button, text: text, url: url}) do
    SlackAPI.Block.build_button_block(text, url)
  end

  ### raw functions

  defmodule Channel do
    defstruct [:id, :name, :user_id, :type]

    def new(%{"id" => id, "name" => name, "is_private" => is_private}) do
      type =
        case is_private do
          false -> :public_channel
          true -> :private_channel
        end

      %__MODULE__{id: id, name: name, type: type}
    end

    def new(%{"id" => id, "user" => user_id, "is_im" => true}) do
      %__MODULE__{id: id, user_id: user_id, type: :direct_message}
    end

    def update_user_name(%__MODULE__{user_id: user_id} = struct, users)
        when not is_nil(user_id) do
      %{name: user_name} =
        users
        |> Enum.find(&(&1.id == user_id))

      %__MODULE__{struct | name: user_name}
    end

    def update_user_name(%__MODULE__{user_id: nil} = struct, _users) do
      struct
    end
  end

  defmodule User do
    defstruct [:id, :name, :type, :deleted]

    def new(%{"id" => id, "name" => name, "is_bot" => is_bot, "deleted" => deleted}) do
      type =
        case {id, is_bot} do
          {"USLACKBOT", _} -> :bot
          {_, true} -> :bot
          _ -> :user
        end

      %__MODULE__{id: id, name: name, type: type, deleted: deleted}
    end
  end

  defmodule Pagination do
    defstruct [:next_cursor]

    def new(%{"next_cursor" => next_cursor}) do
      next_cursor =
        case next_cursor do
          "" -> nil
          next_cursor -> next_cursor
        end

      %__MODULE__{next_cursor: next_cursor}
    end
  end

  def list_channels(credentials, params \\ %{}) do
    do_list_channels(credentials, params)
  end

  def list_users(credentials, params \\ %{}) do
    do_list_users(credentials, params)
  end

  def post_message(channel_id, blocks, %{bot_token: bot_token}) do
    SlackAPI.post_message(channel_id, blocks, bot_token)
  end

  defp do_list_channels(%{bot_token: bot_token} = credentials, params) do
    Stream.unfold(nil, fn
      false ->
        nil

      next_cursor ->
        {:ok, %{channels: channels, pagination: %Pagination{next_cursor: next_cursor}}} =
          SlackAPI.list_conversations(
            params
            |> Map.merge(%{
              scope: credentials[:bot_scope],
              cursor: next_cursor
            }),
            bot_token
          )

        case next_cursor do
          nil -> {channels, false}
          next_cursor -> {channels, next_cursor}
        end
    end)
    |> Enum.to_list()
    |> List.flatten()
    |> then(&{:ok, &1})
  end

  defp do_list_users(%{bot_token: bot_token}, params) do
    Stream.unfold(nil, fn
      false ->
        nil

      next_cursor ->
        {:ok, %{users: users, pagination: %Pagination{next_cursor: next_cursor}}} =
          SlackAPI.list_users(
            params
            |> Map.merge(%{
              cursor: next_cursor
            }),
            bot_token
          )

        case next_cursor do
          nil -> {users, false}
          next_cursor -> {users, next_cursor}
        end
    end)
    |> Enum.to_list()
    |> List.flatten()
    |> then(&{:ok, &1})
  end
end
