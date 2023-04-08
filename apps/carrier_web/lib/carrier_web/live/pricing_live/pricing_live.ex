defmodule CarrierWeb.PricingLive do
  use CarrierWeb, :live_view
  alias Carrier.Billing
  alias Carrier.Billing.Plan
  alias CarrierWeb.Components.Icon
  alias Phoenix.LiveView.JS

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:plans_by_billing_cycle, %{
        monthly: [],
        yearly: []
      })
      |> assign(:selected_billing_cycle, "yearly")

    socket = socket |> load_plans_by_billing_cycle()

    {:ok, socket}
  end

  @impl true
  def handle_event("select_billing_cycle", %{"billing-cycle" => billing_cycle}, socket) do
    socket = socket |> assign(:selected_billing_cycle, billing_cycle)

    {:noreply, socket}
  end

  @impl true
  def handle_event("click_link", %{"name" => name, "to" => to}, socket) do
    socket =
      socket
      |> log_event(name, %{
        page_name: "pricing"
      })

    {:noreply, push_navigate(socket, to: to)}
  end

  defp load_plans_by_billing_cycle(socket) do
    case Billing.list_subscribable_plans() do
      {:ok, plans} ->
        plans_by_billing_cycle =
          plans
          |> Enum.group_by(fn plan -> plan.billing_cycle end)
          |> Enum.map(fn {billing_cycle, plans} ->
            {billing_cycle, plans |> Enum.sort_by(fn plan -> plan.price end)}
          end)
          |> Enum.into(%{})

        socket |> assign(:plans_by_billing_cycle, plans_by_billing_cycle)
    end
  end
end
