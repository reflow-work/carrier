defmodule CarrierWeb.App.PaymentLive do
  use CarrierWeb, :live_view

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
