defmodule Carrier.Data.Source do
  @callback load_raw_data(data_source :: map(), params :: map()) ::
              {:ok, list()} | {:error, any()}
  @callback transform_data(data_source :: map(), raw_data :: list()) ::
              {:ok, list()} | {:error, any()}
  @callback data_to_threads(data_source :: map(), data :: list()) ::
              {:ok, list()} | {:error, any()}

  use Carrier.Integrations
  alias __MODULE__.Tableau

  defmacro __using__([]) do
    quote do
      alias unquote(__MODULE__)
      alias unquote(__MODULE__).Tableau
    end
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
    case source do
      :tableau -> Tableau
    end
  end
end
