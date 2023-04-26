defmodule CarrierWeb.App.SubscriptionLive.Done do
  use CarrierWeb, :live_view
  use Carrier.{Billing, Payments}
  alias Carrier.Core.{TimezoneHelper, DateHelper}

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> load_active_subscription()
      |> load_pending_subscription()

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <section class="page-container">
      <.page_header icon="💳" title="구독 완료" />

      <.card_container>
        <.card>
          <.card_title title="구독 정보" />
          <div class="space-y-1">
            <div>
              <span class="text-lg font-bold"><%= @active_subscription.plan.name %></span>
              <span :if={@active_subscription.plan.billing_cycle != :none}>
                (<%= @active_subscription.plan.billing_cycle |> to_string() |> String.capitalize() %>)
              </span>
            </div>
            <div>
              구독 기간: <%= format_date(@active_subscription.start_on) %> - <%= format_date(
                @active_subscription.end_on
              ) %>
            </div>
            <div :if={@pending_subscription}>
              다음 결제 예정일: <%= format_date(@pending_subscription.start_on) %>
            </div>
            <div :if={@active_subscription.payment}>
              결제 수단: <%= CreditCard.format_card_info(@active_subscription.payment.credit_card) %>
            </div>
          </div>
        </.card>
      </.card_container>
    </section>
    """
  end

  defp load_active_subscription(socket) do
    case Billing.fetch_active_subscription() do
      {:ok, subscription} ->
        socket |> assign(:active_subscription, subscription)

      {:error, _} ->
        nil
    end
  end

  defp load_pending_subscription(socket) do
    case Billing.fetch_pending_subscription() do
      {:ok, subscription} ->
        socket |> assign(:pending_subscription, subscription)

      {:error, _} ->
        socket
    end
  end
end
