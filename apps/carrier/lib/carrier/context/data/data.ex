defmodule Carrier.Data do
  use Carrier.Integrations
  alias __MODULE__.{Source, Target, Block}

  defmacro __using__([]) do
    quote do
      use unquote(__MODULE__).{Source, Target}
      alias unquote(__MODULE__)
    end
  end

  def validate_conn(source, credentials, type, opts \\ []) do
    case type do
      :source -> Source.validate_conn(source, credentials, opts)
      :target -> Target.validate_conn(source, credentials, opts)
    end
  end

  def prepare_threads(%{data_source_info: %{data_source_id: data_source_id}} = params) do
    with {:ok, %DataSource{} = data_source} <- Integrations.fetch_data_source(data_source_id),
         {:ok, raw_data} <- Source.load_raw_data(params, data_source),
         {:ok, transformed_data} <- Source.transform_data(params, data_source, raw_data),
         {:ok, threads} <- Source.data_to_threads(params, data_source, transformed_data) do
      {:ok, threads}
    end
  end

  def send_failure_message(%{name: name, link: link, data_target_info: data_target_info}) do
    threads = [
      [
        Block.text("리포트 발송에 실패하였습니다. 아래 링크에서 확인해주세요."),
        Block.link("reflow로 이동하기", link)
      ]
    ]

    send_messages(%{name: name, text: nil}, threads, data_target_info)
  end

  def send_messages(
        %{name: _name, text: _text} = header,
        threads,
        %{data_target_id: data_target_id, params: params}
      ) do
    with {:ok, %DataTarget{} = data_target} <- Integrations.fetch_data_target(data_target_id),
         {:ok, header_messages} <- Target.header_to_messages(data_target, header),
         {:ok, messages} <- Target.threads_to_messages(data_target, threads),
         :ok <- Target.send_messages(data_target, header_messages, messages, params) do
      :ok
    end
  end
end
