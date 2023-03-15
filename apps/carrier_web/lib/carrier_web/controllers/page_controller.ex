defmodule CarrierWeb.PageController do
  use CarrierWeb, :controller

  def index(conn, _params) do
    conn
    |> redirect(to: ~p"/app/reports")
  end
end
