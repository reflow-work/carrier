defmodule Carrier.Schema do
  import Ecto.Query

  defmacro __using__([]) do
    quote do
      use Ecto.Schema
      import unquote(__MODULE__)
      import Ecto.Changeset
      import Ecto.Query

      @timestamps_opts [type: :utc_datetime_usec, inserted_at: :created_at]
    end
  end

  def where_not_deleted(query) do
    query
    |> where([x], is_nil(x.deleted_at))
  end
end
