defmodule CarrierWeb.App.BillingLive do
  use CarrierWeb, :live_view
  use Carrier.Payments

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <section class="page-container">
      <.page_header icon="💳" title="결제" />
    </section>
    """
  end
end
