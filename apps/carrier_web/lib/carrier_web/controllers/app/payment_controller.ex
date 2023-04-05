defmodule CarrierWeb.App.PaymentController do
  use CarrierWeb, :controller
  require Logger
  alias Carrier.External
  alias Carrier.Core.Crypto

  def toss_payments_callback(conn, %{"customerKey" => customer_key, "authKey" => auth_key}) do
    with org_id = Crypto.deobfuscate!(customer_key),
         ^org_id <- conn |> get_session(:org_id),
         {:ok, %External.Model.CreditCard{billing_key: _billing_key, customer_key: ^customer_key}} <-
           External.TossPayments.issue_billing_auth(auth_key, customer_key) do
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
    |> put_flash(:error, "결제에 실패했습니다. 다시 시도해주세요. #{message}")
    |> redirect(to: ~p"/app/payment")
  end
end
