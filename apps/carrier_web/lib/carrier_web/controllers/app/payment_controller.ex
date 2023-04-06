defmodule CarrierWeb.App.PaymentController do
  use CarrierWeb, :controller
  use Carrier.Payments
  require Logger

  def toss_payments_callback(conn, %{"customerKey" => customer_key, "authKey" => auth_key}) do
    org_id = conn |> get_session(:org_id)

    with {:ok, %CreditCard{}} <-
           Payments.create_credit_card(:toss_payments, %{
             org_id: org_id,
             customer_key: customer_key,
             auth_key: auth_key
           }) do
      conn
      |> redirect(to: ~p"/app/payment/done")
    else
      {:error, reason} ->
        Logger.error("Failed to pay with toss payments: #{org_id} - #{reason}")

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
