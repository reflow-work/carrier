defmodule CarrierWeb.App.PaymentLive.Done do
  use CarrierWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <section class="page-container">
      <header class="page-header">
        <h1 class="page-title">
          <span class="page-title-icon">💳</span> 플랜 선택하기
        </h1>
      </header>

      <div class="mt-6 grid grid-cols-12 gap-4">
        <div class="col-span-8 card">
          <div class="card-body">
            <h2 class="card-title">
              결제가 완료되었습니다
            </h2>
          </div>
        </div>
      </div>
    </section>
    """
  end
end
