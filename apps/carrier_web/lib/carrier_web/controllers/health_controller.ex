defmodule CarrierWeb.HealthController do
  use CarrierWeb, :controller

  def index(conn, _params) do
    conn |> text("healthy")
  end
end
