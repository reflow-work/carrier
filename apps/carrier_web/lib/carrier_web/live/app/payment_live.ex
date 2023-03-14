defmodule CarrierWeb.App.PaymentLive do
  use CarrierWeb, :live_view
  alias Carrier.Core.Crypto

  on_mount(CarrierWeb.TossHook)

  @impl true
  def mount(_params, _session, socket) do
    plans = list_plans()

    socket =
      socket
      |> assign(:plans, plans)
      |> assign(:selected_plan, plans |> List.first())

    {:ok, socket}
  end

  @impl true
  def handle_event("select_plan", %{"plan_id" => plan_id}, socket) do
    selected_plan =
      socket.assigns.plans
      |> Enum.find(&(&1.id == plan_id))

    socket =
      socket
      |> assign(:selected_plan, selected_plan)

    {:noreply, socket}
  end

  @impl true
  def handle_event("request_payment", _, socket) do
    customer_key = Crypto.obfuscate(socket.assigns.org_id)

    socket =
      socket
      |> push_event("toss-payments-request", %{
        customer_key: customer_key,
        success_url: Routes.app_payment_url(socket, :toss_payments_callback),
        fail_url: Routes.app_payment_url(socket, :toss_payments_callback)
      })

    {:noreply, socket}
  end

  defp list_plans() do
    [
      %{
        id: 1,
        name: "Yearly",
        price: 39000
      },
      %{
        id: 2,
        name: "Monthly",
        price: 49000
      }
    ]
  end
end
