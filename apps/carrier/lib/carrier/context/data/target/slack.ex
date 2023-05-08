defmodule Carrier.Data.Target.Slack do
  @behaviour Carrier.Data.Target

  use Carrier.Integrations
  alias Carrier.External.SlackAPI

  @impl true
  def threads_to_report_messages(%DataTarget{service_name: :slack}, threads) do
    threads
    |> Enum.map(fn blocks ->
      blocks |> Enum.map(&block_to_report_message/1)
    end)
  end

  defp block_to_report_message(%{type: :text, text: text, style: style}) do
    text =
      case style do
        :normal -> text
        :bold -> "*#{text}*"
      end

    SlackAPI.Block.build_text_block(text)
  end

  defp block_to_report_message(%{
         type: :image,
         title: title,
         image_url: image_url,
         alt_text: alt_text
       }) do
    SlackAPI.Block.build_image_block(image_url, title, alt_text)
  end

  ### raw functions

  defmodule Channel do
    defstruct [:id, :name, :is_private]

    def new(%{"id" => id, "name" => name, "is_private" => is_private}) do
      %__MODULE__{id: id, name: name, is_private: is_private}
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

  def list_channels(credentials) do
    do_list_channels(credentials)
  end

  defp do_list_channels(%{bot_token: bot_token}) do
    Stream.unfold(nil, fn
      false ->
        nil

      next_cursor ->
        {:ok, %{channels: channels, pagination: %Pagination{next_cursor: next_cursor}}} =
          SlackAPI.list_conversations(%{cursor: next_cursor}, bot_token)

        case next_cursor do
          nil -> {channels, false}
          next_cursor -> {channels, next_cursor}
        end
    end)
    |> Enum.to_list()
    |> List.flatten()
    |> then(&{:ok, &1})
  end
end
