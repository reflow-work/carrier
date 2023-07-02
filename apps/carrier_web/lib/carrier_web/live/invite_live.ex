defmodule CarrierWeb.InviteLive do
  use CarrierWeb, :live_view
  use Carrier.Accounts
  alias Carrier.External.Google

  @impl true
  def mount(%{"invite_token" => invite_token}, _session, socket) do
    org_id = invite_token |> Obfuscatable.deobfuscate!(Org)

    socket =
      case Accounts.Super.get_org(org_id) do
        {:ok, org} ->
          socket
          |> assign(org: org, invite_token: invite_token)

        _ ->
          socket
          |> assign(org: nil, invite_token: nil)
      end

    {:ok, socket, layout: false}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="h-screen">
      <div class="flex flex-col justify-center items-center text-center h-[40%]">
        <Icon.logo class="w-36 mb-2" />

        <div :if={@org}>
          <div class="text-lg font-bold mt-2">reflow에 오신 것을 환영합니다! 🎉</div>
          <div class="text-sm mt-4">
            reflow는 데이터 보는 문화를 만들어주는 서비스입니다. <br /> 동료들과 함께 데이터 리포트를 확인하세요.
          </div>
        </div>

        <div :if={!@org}>
          <div class="text-lg font-bold mt-2">잘못된 초대 링크입니다. 👻</div>
          <div class="text-sm mt-4">
            초대 링크를 다시 한 번 확인해주세요.
          </div>
        </div>
      </div>

      <div :if={@org} class="bg-white flex-1 h-[60%] flex flex-col items-center text-center pt-10">
        <div class="mt-2 text-sm">
          <span class="font-bold"><%= @org.name %></span>에 초대되었습니다.<br />
          구글 계정으로 로그인하여 reflow를 이용해보세요.
        </div>
        <div class="flex items-center mt-12">
          <div
            id="google_signin_info"
            data-client_id={Google.OAuth.client_id()}
            data-ux_mode="redirect"
            data-login_uri={url(~p"/auth/google/callback?invite_token=#{@invite_token}")}
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
