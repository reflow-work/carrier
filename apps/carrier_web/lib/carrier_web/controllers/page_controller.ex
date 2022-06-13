defmodule CarrierWeb.PageController do
  use CarrierWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
