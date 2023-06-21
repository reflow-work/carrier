defmodule CarrierWeb.TestController do
  use CarrierWeb, :controller

  def index(conn, _params) do
    conn
    |> render(:index)
  end
end
