defmodule CarrierWeb.App.SettingsLive.Components.Billing do
  use CarrierWeb, :live_component
  use Carrier.{Billing, Payments}
  import CarrierWeb.ChanneltalkHelper

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
          <.card_title title="현재 플랜" />
          <div :if={@active_subscription} class="border p-4 rounded-md">
            <p class="text-xl font-bold">
              <%= Plan.get_full_name(@active_subscription.plan) %>
            </p>
            <div class="text-sm mt-6 flex">
              <div class="w-32 text-description">구독 기간</div>
              <div>
                <%= format_date(@active_subscription.start_on) %> - <%= format_date(
                  @active_subscription.end_on
                ) %>
              </div>
            </div>
          </div>

          <.card_title :if={@pending_subscription} title="예정된 플랜" class="mt-6" />
          <div :if={@pending_subscription} class="border p-4 rounded-md">
            <p class="text-xl font-bold">
              <%= Plan.get_full_name(@pending_subscription.plan) %>
            </p>
            <div class="text-sm mt-6 flex">
              <div class="w-32 space-y-2 text-description">
                <div>결제 예정일</div>
                <div>구독 기간</div>
                <div :if={@credit_card && has_billing_payment_permission(@user)}>
                  결제 수단
                </div>
                <div :if={@pending_subscription.payment}>결제 예정 금액</div>
              </div>
              <div class="space-y-2">
                <div><%= format_date(@pending_subscription.start_on) %></div>
                <div>
                  <%= format_date(@pending_subscription.start_on) %> - <%= format_date(
                    @pending_subscription.end_on
                  ) %>
                </div>
                <div :if={@pending_subscription.payment}>
                  <%= format_money(
                    @pending_subscription.payment.amount,
                    @pending_subscription.payment.currency
                  ) %> (VAT 10% 포함)
                </div>
                <div
                  :if={@credit_card && has_billing_payment_permission(@user)}
                  class="flex items-center"
                >
                  <.icon name="hero-credit-card" class="mt-0.5 h-5 w-5 flex-none mr-1.5" /> <%= CreditCard.format_card_info(
                    @credit_card
                  ) %>
                </div>
              </div>
            </div>
            <div class="text-sm text-description mt-6">
              구독 취소는 <.link href="https://reflow-work.channel.io/" target="_blank" class="link">채널톡</.link>으로 문의해주세요.
            </div>
          </div>

          <%= if !@active_subscription and !@pending_subscription do %>
            <div class="text-sm">
              <div>현재 구독 중인 플랜이 없습니다.</div>
              <.link
                :if={has_billing_payment_permission(@user)}
                navigate={~p"/app/subscriptions/new"}
                class="text-primary-red font-bold mt-6 w-full flex items-center"
              >
                구독하러 가기 <.icon name="hero-arrow-small-right-mini" class="w-6 h-6" />
              </.link>
            </div>
          <% end %>
        </.card>
        <.card :if={has_billing_payment_permission(@user)}>
          <.card_title title="결제 목록" />
          <.table id="payments" rows={@payments}>
            <:col :let={payment} label="결제일"><%= format_date(payment.confirmed_at) %></:col>
            <:col :let={payment} label="결제액">
              <%= format_money(payment.amount, payment.currency) %>
            </:col>
            <:col :let={payment} label="플랜"><%= payment.item %></:col>
          </.table>
        </.card>
        <div :if={has_billing_payment_permission(@user)} class="text-right text-sm text-description">
          <.link phx-click={js_open_channel_talk()}>환불문의</.link>
        </div>
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

  defp has_billing_payment_permission(user) do
    "billing.payment.manage" in user.role.permissions
  end
end
