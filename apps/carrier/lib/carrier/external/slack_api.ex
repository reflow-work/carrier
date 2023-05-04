defmodule Carrier.External.SlackAPI do
  require Logger
  alias Carrier.Data.Target.Slack.{Channel, Pagination}

  def post_message(channel_id, message, token) when is_binary(message) do
    query = [channel: channel_id, text: message]

    Tesla.get(client(token), "/chat.postMessage", query: query)
    |> handle_response()
    |> case do
      {:ok, _body} ->
        :ok

      {:error, reason} ->
        Logger.error(reason)

        {:error, reason}
    end
  end

  def post_message(channel_id, blocks, token) when is_list(blocks) do
    body = %{channel: channel_id, blocks: blocks}

    Tesla.post(client(token), "/chat.postMessage", body)
    |> handle_response()
    |> case do
      {:ok, _body} ->
        :ok

      {:error, reason} ->
        Logger.error(%{reason: inspect(reason), channel_id: channel_id, blocks: blocks})

        {:error, reason}
    end
  end

  def list_conversations(params \\ nil, token) do
    query =
      %{
        "types" => "public_channel,private_channel",
        "exclude_archived" => true,
        "limit" => params[:limit] || 1000,
        "cursor" => params[:cursor]
      }
      |> Map.reject(fn {_key, value} -> is_nil(value) end)

    Tesla.get(client(token), "/conversations.list", query: query)
    |> handle_response()
    |> case do
      {:ok, %{"channels" => channels, "response_metadata" => response_metadata}} ->
        {:ok,
         %{
           channels: channels |> Enum.map(&Channel.new/1),
           pagination: Pagination.new(response_metadata)
         }}

      {:error, reason} ->
        Logger.error(reason)

        {:error, reason}
    end
  end

  def get_conversation(channel_id, token) do
    Tesla.get(client(token), "/conversations.info", query: %{channel: channel_id})
    |> handle_response()
  end

  # data :: %{ dynamic_column_name: %{ data: list(), meta: map() }, ... }
  def build_post_message_args(data, img_urls) do
    data
    |> Map.to_list()
    |> Enum.map(fn {k, v} ->
      %{
        title: v.meta.label,
        img_url: Map.get(img_urls, k)
      }
    end)
  end

  defp handle_response(response) do
    case response do
      {:ok, %Tesla.Env{status: 200, body: %{"ok" => true} = body}} ->
        {:ok, body}

      {:ok, %Tesla.Env{status: 200, body: %{"ok" => false, "error" => reason}}} ->
        {:error, reason}

      {:ok, %Tesla.Env{status: _, body: body}} ->
        {:error, body}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp client(token) do
    Tesla.client([
      {Tesla.Middleware.BaseUrl, base_url()},
      {Tesla.Middleware.BearerAuth, token: token},
      {Tesla.Middleware.Retry,
       delay: 500,
       max_retries: 3,
       max_delay: 4_000,
       should_retry: fn
         {:ok, %{status: 200, body: %{"ok" => true}}} -> false
         _ -> true
       end},
      {Tesla.Middleware.JSON, encode_content_type: "application/json; charset=utf-8"},
      {Tesla.Middleware.Timeout, timeout: :timer.seconds(10)}
    ])
  end

  defp base_url() do
    Application.get_env(:carrier, :slack)[:base_url]
  end
end
