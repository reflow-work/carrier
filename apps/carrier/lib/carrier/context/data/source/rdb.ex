defmodule Carrier.Data.Source.RDB do
  @callback tables_query() :: String.t()
  @callback table_name_field() :: String.t()
  @callback columns_query() :: String.t()
  @callback column_name_field() :: String.t()
  @callback data_type_field() :: String.t()
  @callback is_date_type?(type :: String.t()) :: boolean()
  @callback param(n :: integer()) :: String.t()
  @callback run_query(credentials :: map(), sql :: String.t(), params :: map()) ::
              {:ok, %{columns: list(), rows: list()}} | {:error, any()}
end
