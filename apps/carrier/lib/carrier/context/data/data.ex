defmodule Carrier.Data do
  use Carrier.Integrations
  alias __MODULE__.{Source, Target}

  defmacro __using__([]) do
    quote do
      use unquote(__MODULE__).{Source, Target}
      alias unquote(__MODULE__)
    end
  end

  def prepare_threads(%{data_source_id: data_source_id, params: params}) do
    with {:ok, %DataSource{} = data_source} <- Integrations.fetch_data_source(data_source_id),
         {:ok, raw_data} <- Source.load_raw_data(data_source, params),
         {:ok, transformed_data} <- Source.transform_data(data_source, raw_data),
         {:ok, threads} <- Source.data_to_threads(data_source, transformed_data) do
      {:ok, threads}
    end
  end

  def send_threads(threads, %{data_target_id: data_target_id, params: params}) do
    with {:ok, %DataTarget{} = data_target} <- Integrations.fetch_data_target(data_target_id),
         {:ok, messages} <- Target.threads_to_messages(data_target, threads),
         :ok <- Target.send_messages(data_target, messages, params) do
      :ok
    end
  end
end
