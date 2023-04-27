defmodule CarrierWeb.App.BillingLive do
  use CarrierWeb, :live_view
  use Carrier.Payments

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:payments, [])
      |> load_payments()

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <section class="page-container">
      <.page_header icon="💳" title="결제" />

      <.card_container>
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
    </section>
    """
  end

  # TODO: remove connected condition
  defp load_payments(socket) do
    with true <- connected?(socket),
         {:ok, payments} <- Payments.list_confirmed_payments() do
      socket |> assign(:payments, payments)
    else
      _ -> socket
    end
  end
end
