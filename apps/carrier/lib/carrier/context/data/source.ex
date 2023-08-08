defmodule Carrier.Data.Source do
  @callback validate_conn(source :: atom(), credentials :: map(), opts :: keyword()) ::
              :ok | {:error, any()}

  @callback load_raw_data(params :: map(), data_source :: map()) ::
              {:ok, list()} | {:error, any()}
  @callback transform_data(params :: map(), data_source :: map(), raw_data :: any()) ::
              {:ok, list()} | {:error, any()}
  @callback data_to_threads(params :: map(), data_source :: map(), data :: any()) ::
              {:ok, list()} | {:error, any()}

  use Carrier.Integrations
  import Carrier.Data.Source.RDB.Guard

  defmacro __using__([]) do
    quote do
      alias unquote(__MODULE__)
      alias unquote(__MODULE__).{RDB, Tableau, Redash, RDBOld}
    end
  end

  def validate_conn(source, credentials, opts) do
    source_module = source_to_module(source)

    source_module.validate_conn(source, credentials, opts)
  end

  def load_raw_data(params, %DataSource{} = data_source) do
    source_module = data_source_to_module(data_source)

    source_module.load_raw_data(params, data_source)
  end

  def transform_data(params, %DataSource{} = data_source, raw_data) do
    source_module = data_source_to_module(data_source)

    source_module.transform_data(params, data_source, raw_data)
  end

  def data_to_threads(params, %DataSource{} = data_source, data) do
    source_module = data_source_to_module(data_source)

    source_module.data_to_threads(params, data_source, data)
  end

  defp data_source_to_module(%DataSource{source: source}) do
    source_to_module(source)
  end

  defp source_to_module(source) do
    case source do
      source when is_rdb_source(source) -> __MODULE__.RDBOld
      :tableau -> __MODULE__.Tableau
      :redash -> __MODULE__.Redash
      :amplitude -> __MODULE__.Amplitude
    end
  end
end
