defmodule Carrier.Data.Source do
  @callback validate_conn(source :: atom(), credentials :: map(), opts :: keyword()) ::
              :ok | {:error, any()}

  @callback load_raw_data(data_source :: map(), params :: map()) ::
              {:ok, list()} | {:error, any()}
  @callback transform_data(data_source :: map(), raw_data :: list()) ::
              {:ok, list()} | {:error, any()}
  @callback data_to_threads(data_source :: map(), data :: list()) ::
              {:ok, list()} | {:error, any()}

  use Carrier.Integrations
  import Carrier.Data.Source.RDB.Guard
  alias __MODULE__.{RDB, Tableau}

  defmacro __using__([]) do
    quote do
      alias unquote(__MODULE__)
      alias unquote(__MODULE__).{RDB, Tableau}
    end
  end

  def validate_conn(source, credentials, opts) do
    source_module = source_to_module(source)

    source_module.validate_conn(source, credentials, opts)
  end

  def load_raw_data(%DataSource{} = data_source, params) do
    source_module = data_source_to_module(data_source)

    source_module.load_raw_data(data_source, params)
  end

  def transform_data(%DataSource{} = data_source, raw_data) do
    source_module = data_source_to_module(data_source)

    source_module.transform_data(data_source, raw_data)
  end

  def data_to_threads(%DataSource{} = data_source, data) do
    source_module = data_source_to_module(data_source)

    source_module.data_to_threads(data_source, data)
  end

  defp data_source_to_module(%DataSource{source: source}) do
    source_to_module(source)
  end

  defp source_to_module(source) do
    case source do
      source when is_rdb_source(source) -> RDB
      :tableau -> Tableau
    end
  end
end
