defmodule CarrierWeb.App.SubscriptionLive.New do
  use CarrierWeb, :live_view
  use Carrier.{Billing, Payments}
  alias CarrierWeb.TossPaymentsHelper

  on_mount(CarrierWeb.SubscriptionRedirectionHook)

  @impl true
  def mount(%{"plan_id" => obfuscated_plan_id}, _session, socket) do
    plan_id = Obfuscatable.deobfuscate!(obfuscated_plan_id, Plan)

    socket =
      socket
      |> assign(plan_id: plan_id)
      |> assign(plan: nil)
      |> assign(:credit_card, nil)
      |> load_plan()
      |> load_credit_card()
      |> TossPaymentsHelper.init()

    {:ok, socket}
  end

  @impl true
  def handle_event("request_payment", _, socket) do
    socket =
      case socket.assigns.credit_card do
        nil ->
          socket
          |> TossPaymentsHelper.issue_billing_key(socket.assigns.plan)

        _ ->
          Billing.start_subscription(%{
            org_id: socket.assigns.org.org_id,
            plan_id: socket.assigns.plan.id,
            start_on: DateTime.utc_now()
          })
          |> case do
            {:ok, %Subscription{} = subscription} ->
              socket
              |> push_navigate(to: ~p"/app/subscriptions/done?subscription_id=#{subscription}")

            {:error, reason} ->
              Logger.error(
                "Failed to start subscription: org_id: #{socket.assigns.org.org_id}, #{inspect(reason)}"
              )

              socket
              |> put_flash_for(:error, "구독 신청에 실패했습니다. 다시 시도해주세요.", timeout: :timer.seconds(3))
          end
      end

    {:noreply, socket}
  end

  defp load_plan(socket) do
    case Billing.Super.fetch_plan(socket.assigns.plan_id) do
      {:ok, plan} -> socket |> assign(:plan, plan)
      {:error, _} -> socket
    end
  end

  defp load_credit_card(socket) do
    case Payments.fetch_default_credit_card() do
      {:ok, credit_card} -> socket |> assign(:credit_card, credit_card)
      {:error, _} -> socket
    end
  end
end
