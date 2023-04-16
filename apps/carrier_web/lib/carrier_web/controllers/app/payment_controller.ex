defmodule CarrierWeb.App.PaymentController do
  use CarrierWeb, :controller
  use Carrier.{Payments, Billing}
  require Logger

  def toss_payments_callback(
        conn,
        %{"customerKey" => customer_key, "authKey" => auth_key, "plan_id" => plan_id_str}
      ) do
    org_id = conn |> get_session(:org_id)
    plan_id = plan_id_str |> String.to_integer()

    with {:ok, %CreditCard{}} <-
           Payments.create_credit_card(:toss_payments, %{
             org_id: org_id,
             customer_key: customer_key,
             auth_key: auth_key
           }),
         {:ok, %Subscription{}} <-
           Billing.start_subscription(%{
             org_id: org_id,
             plan_id: plan_id,
             start_on: DateTime.utc_now()
           }) do
      conn
      |> redirect(to: ~p"/app/subscriptions/done")
    else
      {:error, reason} ->
        Logger.error("Failed to pay with toss payments: org_id: #{org_id}, #{inspect(reason)}")

        conn
        |> put_flash(:error, "결제에 실패했습니다. 다시 시도해주세요.")
        |> redirect(to: ~p"/app/subscriptions/new")
    end
  end

  def toss_payments_callback(conn, %{"code" => code, "message" => message}) do
    Logger.error("Failed to pay with toss payments: #{code}, #{message}")

    conn
    |> put_flash(:error, "결제에 실패했습니다. 다시 시도해주세요. #{message}")
    |> redirect(to: ~p"/app/subscriptions/new")
  end
end
