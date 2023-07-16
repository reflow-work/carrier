defmodule Carrier.Pagex do
  @callback generate_query(query :: Ecto.Query.t(), pagination :: %Carrier.Pagex.Cursor{}) ::
              query :: Ecto.Query.t()
  @callback generate_result(entries :: [any()], pagination :: %Carrier.Pagex.Cursor{}) ::
              %Carrier.Pagex.Result{}

  defmacro __using__(_) do
    quote do
      def paginate(query, pagination) do
        unquote(__MODULE__).paginate(query, pagination, __MODULE__)
      end
    end
  end

  def paginate(query, %module{} = pagination, repo) do
    module.generate_query(query, pagination)
    |> repo.all()
    |> module.generate_result(pagination)
  end
end
