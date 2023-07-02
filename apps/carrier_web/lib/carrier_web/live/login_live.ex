defmodule CarrierWeb.LoginLive do
  use CarrierWeb, :live_view
  alias Carrier.External.Google

  @impl true
  def mount(_params, session, socket) do
    socket =
      case session["user_id"] do
        nil -> socket
        _ -> socket |> push_navigate(to: ~p"/app/reports")
      end

    {:ok, socket, layout: false}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex flex-col items-center h-screen max-w-5xl w-full mx-auto px-8 py-20">
      <div class="flex-1 flex flex-row rounded-2xl overflow-hidden bg-white w-full shadow">
        <div class="flex flex-col flex-1 items-center justify-center bg-base-dark text-primary-content pb-8">
          <div>
            <Icon.logo_white class="w-36 mb-2" />
          </div>
          <div class="text-2xl font-bold">
            단 5분만에 데이터 분석 환경 구축
          </div>
        </div>

        <div class="flex flex-col flex-1 items-center justify-center relative">
          <div
            id="google_signin_info"
            data-client_id={Google.OAuth.client_id()}
            data-ux_mode="redirect"
            data-login_uri={url(~p"/auth/google/callback")}
          >
          </div>
          <div
            id="google_signin_button"
            phx-hook="GoogleSignIn"
            data-type="standard"
            data-size="large"
            data-theme="filled_black"
            data-text="continue_with"
            data-shape="pill"
          >
          </div>
        </div>
      </div>
    </div>
    """
  end
end
