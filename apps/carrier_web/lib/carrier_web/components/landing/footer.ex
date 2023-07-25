defmodule LandingFooterComponent do
  use CarrierWeb, :live_component
  alias Carrier.Const

  @impl true
  def render(assigns) do
    ~H"""
    <footer class="bg-primary text-white py-6 md:py-20">
      <div class="landing-container flex flex-col md:flex-row justify-between">
        <div class="flex flex-col items-start">
          <Icon.logo_white class="w-40 h-auto mb-4" />
          <div class="text-white">지표보는 문화를 만드는 가장 쉬운 툴, reflow</div>
          <.link
            class="button button-lg mt-8"
            href={Const.get(:demo_call_url)}
            target="_blank"
            phx-click={js_log_event("click_demo_on_footer", %{page_name: "landing"})}
          >
            데모 신청하기
          </.link>
        </div>
        <div>
          <div class="text-lg mt-10 md:mt-0 mb-4">Copyright ⓒ reflow</div>
          <div class="space-y-2 text-sm opacity-80">
            <div>리플로우</div>
            <div>대표자: 손진규</div>
            <div>사업자등록번호: 645-27-01342</div>
            <div>서울시 서초구 반포대로26길 38, 602호</div>
            <div>010-2141-0727</div>
            <div>
              <a href={Const.get(:terms_of_service_url)} target="_blank" class="underline">
                이용약관
              </a>
              |
              <a href={Const.get(:privacy_policy_url)} target="_blank" class="underline">
                개인정보 처리방침
              </a>
            </div>
          </div>
        </div>
      </div>
    </footer>
    """
  end
end
