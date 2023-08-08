defmodule CarrierWebhook.HealthController do
  use CarrierWebhook, :controller

  def index(conn, _params) do
    conn |> text("healthy")
  end
end
