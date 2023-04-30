defmodule CarrierWeb.App.SubscriptionLive.Done do
  use CarrierWeb, :live_view
  use Carrier.{Billing, Payments}

  @impl true
  def mount(%{"subscription_id" => obfuscated_subscription_id}, _session, socket) do
    subscription_id = Crypto.deobfuscate!(obfuscated_subscription_id)

    socket =
      socket
      |> assign(:subscription, nil)
      |> assign(:active_trial_subscription, nil)
      |> load_subscription(subscription_id)
      |> load_active_trial_subscription()

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
            <p class="text-lg font-bold"><%= Plan.get_full_name(@subscription.plan) %></p>
            <p>
              구독 기간: <%= format_date(@subscription.start_on) %> - <%= format_date(
                @subscription.end_on
              ) %>
            </p>
            <p>
              결제 예정일: <%= format_date(@subscription.start_on) %>
              <%= if @active_trial_subscription do %>
                (<%= format_date(@active_trial_subscription.end_on) %> 전까지 무료 Trial Plan)
              <% end %>
            </p>
            <p>
              결제 예정 금액: <%= format_money(@subscription.payment.amount, @subscription.payment.currency) %> (VAT 10% 포함)
            </p>
            <p>
              결제 수단: <%= CreditCard.format_card_info(@subscription.payment.credit_card) %>
            </p>
          </div>
        </.card>
      </.card_container>
    </section>
    """
  end

  defp load_subscription(socket, subscription_id) do
    case Billing.fetch_subscription(subscription_id) do
      {:ok, subscription} ->
        socket |> assign(:subscription, subscription)

      {:error, _} ->
        socket
    end
  end

  defp load_active_trial_subscription(socket) do
    maybe_active_trial_subscription = Billing.get_active_trial_subscription()

    socket
    |> assign(:active_trial_subscription, maybe_active_trial_subscription)
  end
end
