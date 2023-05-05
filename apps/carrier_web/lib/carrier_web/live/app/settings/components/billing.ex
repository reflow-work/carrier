defmodule CarrierWeb.App.SettingsLive.Components.Billing do
  use CarrierWeb, :live_component
  use Carrier.{Billing, Payments}

  @impl true
  def mount(socket) do
    socket =
      socket
      |> assign(:active_subscription, nil)
      |> assign(:pending_subscription, nil)
      |> assign(:credit_card, nil)
      |> assign(:payments, [])
      |> assign_concurrent(%{
        active_subscription: &load_active_subscription/0,
        pending_subscription: &load_pending_subscription/0,
        credit_card: &load_credit_card/0,
        payments: &load_payments/0
      })

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex-1">
      <.card_container class="space-y-4">
        <.card>
          <.card_title title="구독 정보" />

          <div :if={@active_subscription}>
            <p class="text-lg font-bold">
              <%= Plan.get_full_name(@active_subscription.plan) %>
            </p>
            <p>
              구독 기간: <%= format_date(@active_subscription.start_on) %> - <%= format_date(
                @active_subscription.end_on
              ) %>
            </p>
          </div>
          <div :if={@pending_subscription}>
            <p>구독 예정</p>
            <p class="text-lg font-bold">
              <%= Plan.get_full_name(@pending_subscription.plan) %>
            </p>
            <p>
              구독 기간: <%= format_date(@pending_subscription.start_on) %> - <%= format_date(
                @pending_subscription.end_on
              ) %>
            </p>
            <p>
              다음 결제 예정일: <%= format_date(@pending_subscription.start_on) %>
            </p>
            <p :if={@pending_subscription.payment}>
              결제 예정 금액: <%= format_money(
                @pending_subscription.payment.amount,
                @pending_subscription.payment.currency
              ) %> (VAT 10% 포함)
            </p>
            <p :if={@credit_card}>
              결제 수단: <%= CreditCard.format_card_info(@credit_card) %>
            </p>
            <br />
            <p>
              구독 취소 문의: 오른쪽 하단 <.link
                href="https://reflow-work.channel.io/"
                target="_blank"
                class="link"
              >채널톡</.link>으로 문의해주세요.
            </p>
          </div>

          <%= if !@active_subscription and !@pending_subscription do %>
            <.link navigate={~p"/app/subscriptions/new"} class="btn btn-primary">구독하러 가기</.link>
          <% end %>
        </.card>
        <.card>
          <.card_title title="결제 목록" />
          <.table id="payments" rows={@payments}>
            <:col :let={payment} label="결제일"><%= format_date(payment.confirmed_at) %></:col>
            <:col :let={payment} label="결제액">
              <%= format_money(payment.amount, payment.currency) %>
            </:col>
            <:col :let={payment} label="플랜"><%= payment.item %></:col>
          </.table>
        </.card>
        <.card>
          <.card_title title="환불" />
          <div>
            환불 규정:
            <.link class="link" href={Const.get(:refund_policy_url)} target="_blank">
              보기
            </.link>
          </div>
        </.card>
      </.card_container>
    </div>
    """
  end

  defp load_active_subscription() do
    Billing.fetch_active_subscription()
  end

  defp load_pending_subscription() do
    Billing.fetch_pending_subscription()
  end

  defp load_payments() do
    Payments.list_confirmed_payments()
  end

  defp load_credit_card() do
    Payments.fetch_default_credit_card()
  end
end
