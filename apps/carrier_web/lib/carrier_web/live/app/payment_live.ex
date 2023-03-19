defmodule CarrierWeb.App.PaymentLive do
  use CarrierWeb, :live_view
  alias CarrierWeb.TossPaymentsHelper

  @impl true
  def mount(_params, _session, socket) do
    plans = list_plans()

    socket =
      socket
      |> assign(:plans, plans)
      |> assign(:selected_plan, plans |> List.first())
      |> TossPaymentsHelper.init()

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
    socket =
      socket
      |> TossPaymentsHelper.issue_billing_key()

    {:noreply, socket}
  end

  defp list_plans() do
    [
      %{
        id: 1,
        name: "Yearly",
        price: 39000,
        payment_description: "매년 46,8000원 (월 39,000원)"
      },
      %{
        id: 2,
        name: "Monthly",
        price: 49000,
        payment_description: "매월 49,000원"
      }
    ]
  end
end
