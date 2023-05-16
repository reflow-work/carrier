defmodule CarrierWeb.TossPaymentsHelper do
  use CarrierWeb, :verified_routes
  use Carrier.Payments
  import Phoenix.LiveView, only: [push_event: 3]

  def init(socket) do
    socket
    |> push_event("toss-payments-init", %{
      client_key: client_key()
    })
  end

  def issue_billing_key(socket, plan_id) do
    customer_key = CreditCard.gen_customer_key(socket.assigns.org.org_id)

    socket
    |> push_event("toss-payments-request", %{
      customer_key: customer_key,
      success_url: url(~p"/app/payment/callback/toss-payments?plan_id=#{plan_id}"),
      fail_url: url(~p"/app/payment/callback/toss-payments")
    })
  end

  defp client_key() do
    Application.get_env(:carrier, :toss_payments)[:client_key]
  end
end
