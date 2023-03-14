defmodule CarrierWeb.PageController do
  use CarrierWeb, :controller

  def index(conn, _params) do
    conn
    |> redirect(to: Routes.app_report_index_path(conn, :index))
  end
end
