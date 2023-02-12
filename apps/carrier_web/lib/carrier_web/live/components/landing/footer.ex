defmodule LandingFooterComponent do
  use Phoenix.LiveComponent

  import CarrierWeb.AnalyticsHelper

  @impl true
  def render(assigns) do
    ~H"""
    <footer class="bg-primary text-white py-6 md:py-20">
      <div class="landing-container flex flex-col md:flex-row justify-between">
        <div>
          <CarrierWeb.Components.Icon.logo_white class="w-40 h-auto mb-4" />
          <div class="text-white">지표보는 문화를 만드는 가장 쉬운 툴, reflow</div>
          <button
            class="button button-lg mt-8"
            phx-click="click_link"
            phx-value-name="start_on_last_section"
            phx-value-to="/login"
          >
            무료로 시작하기
          </button>
        </div>
        <div>
          <div class="text-lg mt-10 md:mt-0 mb-4">Copyright ⓒ reflow</div>
          <div class="space-y-2 text-sm opacity-80">
            <div>리플로우</div>
            <div>대표자: 손진규</div>
            <div>사업자등록번호: 645-27-01342</div>
            <div>이용약관 | 개인정보처리방침</div>
          </div>
        </div>
      </div>
    </footer>
    """
  end

  @impl true
  def handle_event("click_link", %{"name" => name, "to" => to}, socket) do
    socket =
      socket
      |> log_event(name, %{
        pane_name: "landing"
      })

    {:noreply, push_navigate(socket, to: to)}
  end
end
