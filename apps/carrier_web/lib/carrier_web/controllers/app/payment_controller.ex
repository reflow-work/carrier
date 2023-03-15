defmodule CarrierWeb.App.PaymentController do
  use CarrierWeb, :controller
  require Logger
  alias Carrier.External.TossPayments
  alias Carrier.Core.Crypto

  def toss_payments_callback(conn, %{"customerKey" => customer_key, "authKey" => auth_key}) do
    with org_id = Crypto.deobfuscate!(customer_key),
         ^org_id <- conn |> get_session(:org_id),
         {:ok, %{billing_key: _billing_key, customer_key: ^customer_key}} <-
           TossPayments.issue_billing_auth(auth_key, customer_key) do
      conn
      |> redirect(to: ~p"/app/payment/done")
    else
      {:error, reason} ->
        Logger.error("Failed to pay with toss payments: #{reason}")

        conn
        |> redirect(to: ~p"/app/payment")
    end
  end

  def toss_payments_callback(conn, %{"code" => code, "message" => message}) do
    Logger.error("Failed to pay with toss payments: #{code}, #{message}")

    conn
    |> redirect(to: ~p"/app/payment")
  end
end
