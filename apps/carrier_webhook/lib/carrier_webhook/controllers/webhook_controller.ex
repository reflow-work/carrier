defmodule CarrierWebhook.WebhookController do
  use CarrierWebhook, :controller

  def receive(conn, params) do
    params |> IO.inspect()

    conn |> text("ok")
  end
end
