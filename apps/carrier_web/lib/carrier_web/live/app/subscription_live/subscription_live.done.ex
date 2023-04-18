defmodule CarrierWeb.App.SubscriptionLive.Done do
  use CarrierWeb, :live_view
  use Carrier.{Billing, Payments}
  alias Carrier.Core.{TimezoneHelper, DateHelper}

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> load_active_subscription()

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <section class="page-container">
      <header class="page-header">
        <h1 class="page-title">
          <span class="page-title-icon">💳</span> 구독 완료
        </h1>
      </header>

      <div class="mt-6 grid grid-cols-12 gap-4">
        <div class="col-span-8 card">
          <div class="card-body">
            <h2 class="card-title">
              구독되었습니다.
            </h2>
            <div class="mt-8 space-y-1">
              <div>
                <span class="text-lg font-bold"><%= @active_subscription.plan.name %></span>
                <span :if={@active_subscription.plan.billing_cycle != :none}>
                  (<%= @active_subscription.plan.billing_cycle |> to_string() |> String.capitalize() %>)
                </span>
              </div>
              <div>
                다음 결제 예정일: <%= format_next_payment_date(@active_subscription) %>
              </div>
              <div :if={@active_subscription.payment}>
                결제 수단: <%= CreditCard.format_card_info(@active_subscription.payment.credit_card) %>
              </div>
            </div>
          </div>
        </div>
      </div>
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

  defp format_next_payment_date(%Subscription{end_on: end_on} = _active_subscription) do
    end_on
    |> TimezoneHelper.apply_timezone()
    |> DateHelper.safe_format_date()
  end
end
