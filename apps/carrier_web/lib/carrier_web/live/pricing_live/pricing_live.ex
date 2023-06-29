defmodule CarrierWeb.PricingLive do
  use CarrierWeb, :live_view
  alias Carrier.Billing
  alias Carrier.Billing.Plan
  alias CarrierWeb.Components.Icon

  @preselected_billing_cycle :yearly

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:billing_cycles, [])
      |> assign(:plans_by_billing_cycle, [])

    socket = socket |> load_plans_by_billing_cycle()

    {:ok, socket}
  end

  defp load_plans_by_billing_cycle(socket) do
    case Billing.Super.list_subscribable_plans() do
      {:ok, plans} ->
        plans_by_billing_cycle =
          plans
          |> Enum.group_by(fn plan -> plan.billing_cycle end)
          |> Enum.map(fn {billing_cycle, plans} ->
            {billing_cycle, plans |> Enum.sort_by(fn plan -> plan.price end)}
          end)

        billing_cycles =
          plans_by_billing_cycle
          |> Enum.map(fn {billing_cycle, _plans} -> billing_cycle end)

        socket
        |> assign(:billing_cycles, billing_cycles)
        |> assign(:plans_by_billing_cycle, plans_by_billing_cycle)
    end
  end

  defp is_preselected_billing_cycle(billing_cycle) do
    billing_cycle == @preselected_billing_cycle
  end

  defp select_billing_cycle(billing_cycle) do
    JS.remove_class("bg-black text-white", to: ".billing-cycle-selector")
    |> JS.add_class("bg-black text-white", to: "#billing-cycle-selector-#{billing_cycle}")
    |> JS.add_class("!hidden", to: ".plan")
    |> JS.remove_class("!hidden", to: ".plan-#{billing_cycle}")
  end
end
