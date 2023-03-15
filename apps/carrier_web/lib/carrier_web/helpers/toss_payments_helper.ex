defmodule CarrierWeb.TossPaymentsHelper do
  use CarrierWeb, :verified_routes
  import Phoenix.LiveView, only: [push_event: 3]
  alias Carrier.Core.Crypto

  def init(socket) do
    socket
    |> push_event("toss-payments-init", %{
      client_key: client_key()
    })
  end

  def issue_billing_key(socket) do
    customer_key = Crypto.obfuscate(socket.assigns.org_id)

    socket
    |> push_event("toss-payments-request", %{
      customer_key: customer_key,
      success_url: ~p"/app/payment/callback/toss-payments",
      fail_url: ~p"/app/payment/callback/toss-payments"
    })
  end

  defp client_key() do
    Application.get_env(:carrier, :toss_payments)[:client_key]
  end
end
