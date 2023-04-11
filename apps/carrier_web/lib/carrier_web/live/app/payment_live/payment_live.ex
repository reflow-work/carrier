defmodule CarrierWeb.App.PaymentLive do
  use CarrierWeb, :live_view
  alias Carrier.Billing
  alias Carrier.Billing.Plan
  alias CarrierWeb.TossPaymentsHelper
  alias CarrierWeb.Components.Icon

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:billing_cycles, [])
      |> assign(:plans_by_billing_cycle, [])
      |> assign(:selected_billing_cycle, :yearly)
      |> assign(:selected_type, :basic)
      |> TossPaymentsHelper.init()

    socket = socket |> load_plans_by_billing_cycle()

    {:ok, socket}
  end

  @impl true
  def handle_event("select_billing_cycle", %{"billing-cycle" => billing_cycle}, socket) do
    socket =
      socket
      |> assign(:selected_billing_cycle, billing_cycle |> String.to_atom())

    {:noreply, socket}
  end

  @impl true
  def handle_event("select_type", %{"type" => type}, socket) do
    socket =
      socket
      |> assign(:selected_type, type |> String.to_atom())

    {:noreply, socket}
  end

  @impl true
  def handle_event("request_payment", _, socket) do
    socket =
      socket
      |> TossPaymentsHelper.issue_billing_key()

    {:noreply, socket}
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
          |> Map.new()

        billing_cycles =
          plans_by_billing_cycle
          |> Enum.map(fn {billing_cycle, _plans} -> billing_cycle end)

        socket
        |> assign(:billing_cycles, billing_cycles)
        |> assign(:plans_by_billing_cycle, plans_by_billing_cycle)
    end
  end

  defp selected_plan(plans_by_billing_cycle, selected_billing_cycle, selected_type) do
    plans_by_billing_cycle
    |> Map.get(selected_billing_cycle)
    |> Enum.find(fn plan -> plan.type == selected_type end)
  end

  defp month_price(plans_by_billing_cycle, selected_billing_cycle, selected_type) do
    selected_plan = selected_plan(plans_by_billing_cycle, selected_billing_cycle, selected_type)
    Plan.month_price(selected_plan)
  end
end
