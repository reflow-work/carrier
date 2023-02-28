defmodule CarrierWeb.FallbackPlug do
  use CarrierWeb, :plug
  import Phoenix.Controller

  def init(opts), do: opts

  def call(conn, _opts) do
    conn
    |> redirect(to: Routes.home_path(conn, :index))
  end
end
