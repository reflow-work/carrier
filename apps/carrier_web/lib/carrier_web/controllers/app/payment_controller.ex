defmodule CarrierWeb.App.PaymentController do
  use CarrierWeb, :controller

  def toss_payments_callback(conn, %{"customerKey" => customer_key, "authKey" => auth_key}) do
    conn
    |> json(%{customer_key: customer_key, auth_key: auth_key})
  end
end
