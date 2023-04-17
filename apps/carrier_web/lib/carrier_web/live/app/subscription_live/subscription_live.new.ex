defmodule CarrierWeb.App.SubscriptionLive.New do
  use CarrierWeb, :live_view
  alias Carrier.Billing
  alias Carrier.Billing.Plan
  alias CarrierWeb.TossPaymentsHelper
  alias CarrierWeb.Components.Icon

  on_mount(CarrierWeb.SubscriptionRedirectionHook)

  @impl true
  def mount(params, _session, socket) do
    plan_billing_cycle = get_plan_billing_cycle(params["plan-billing-cycle"])
    plan_type = get_plan_type(params["plan-type"])

    socket =
      socket
      |> assign(:billing_cycles, [])
      |> assign(:plans_by_billing_cycle, [])
      |> assign(:selected_billing_cycle, plan_billing_cycle)
      |> assign(:selected_type, plan_type)
      |> assign(:selected_plan, nil)
      |> TossPaymentsHelper.init()

    socket =
      socket
      |> load_plans_by_billing_cycle()
      |> assign_selected_plan()

    {:ok, socket}
  end

  @impl true
  def handle_event("select_billing_cycle", %{"billing-cycle" => billing_cycle}, socket) do
    socket =
      socket
      |> assign(:selected_billing_cycle, billing_cycle |> String.to_existing_atom())
      |> assign_selected_plan()

    {:noreply, socket}
  end

  @impl true
  def handle_event("select_type", %{"type" => type}, socket) do
    socket =
      socket
      |> assign(:selected_type, type |> String.to_existing_atom())
      |> assign_selected_plan()

    {:noreply, socket}
  end

  @impl true
  def handle_event("request_payment", _, socket) do
    socket =
      socket
      |> TossPaymentsHelper.issue_billing_key(socket.assigns.selected_plan.id)

    {:noreply, socket}
  end

  defp get_plan_billing_cycle(plan_billing_cycle) do
    case plan_billing_cycle do
      nil -> :yearly
      "" -> :yearly
      _ -> plan_billing_cycle |> String.to_existing_atom()
    end
  end

  defp get_plan_type(plan_type) do
    case plan_type do
      nil -> :basic
      "" -> :basic
      _ -> plan_type |> String.to_existing_atom()
    end
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

  defp assign_selected_plan(socket) do
    plans_by_billing_cycle = socket.assigns.plans_by_billing_cycle
    selected_billing_cycle = socket.assigns.selected_billing_cycle
    selected_type = socket.assigns.selected_type

    selected_plan = selected_plan(plans_by_billing_cycle, selected_billing_cycle, selected_type)

    socket
    |> assign(:selected_plan, selected_plan)
  end

  defp selected_plan(plans_by_billing_cycle, selected_billing_cycle, selected_type) do
    plans_by_billing_cycle
    |> Map.get(selected_billing_cycle)
    |> Enum.find(fn plan -> plan.type == selected_type end)
  end
end
