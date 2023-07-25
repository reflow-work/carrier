defmodule LandingHeaderComponent do
  use CarrierWeb, :live_component
  alias Carrier.Const

  @impl true
  def render(assigns) do
    ~H"""
    <header class="header border-b z-10 w-full fixed bg-white">
      <div class="landing-container flex justify-between items-center">
        <a
          class="float-left py-4 cursor-pointer"
          phx-target={@myself}
          phx-click={
            js_log_event("logo_on_header", %{page_name: "landing"})
            |> JS.navigate(~p"/")
          }
        >
          <Icon.logo_with_beta class="w-32" />
        </a>

        <div class="flex items-center">
          <ul class="flex-row hidden md:flex md:mr-4">
            <%= if Carrier.Setting.get_feature_flag_value("blog") do %>
              <li>
                <a
                  class="font-bold cursor-pointer text-base !text-black px-4"
                  phx-target={@myself}
                  phx-click={
                    js_log_event("blog_on_header", %{page_name: "landing"})
                    |> JS.navigate(~p"/blog")
                  }
                >
                  블로그
                </a>
              </li>
            <% end %>
            <li>
              <a
                class="font-bold cursor-pointer text-base !text-black px-4"
                phx-target={@myself}
                phx-click={
                  js_log_event("click_login_on_header", %{page_name: "landing"})
                  |> JS.navigate(~p"/login")
                }
              >
                로그인
              </a>
            </li>
          </ul>
          <.link
            class="button button-primary"
            href={Const.get(:demo_call_url)}
            target="_blank"
            phx-target={@myself}
            phx-click={js_log_event("click_demo_on_header", %{page_name: "landing"})}
          >
            데모 신청하기
          </.link>

          <label class="cursor-pointer pl-3 md:hidden" for="hamburger-button">
            <Icon.menu class="w-8" />
          </label>
        </div>
      </div>

      <input class="hamburger-button hidden" type="checkbox" id="hamburger-button" />

      <div class="mobile-menu-list overflow-hidden md:hidden">
        <ul>
          <li>
            <a
              class="w-full block font-bold cursor-pointer px-4 py-4 text-sm"
              phx-target={@myself}
              phx-click={
                js_log_event("click_login_on_header", %{page_name: "landing"})
                |> JS.navigate(~p"/login")
              }
            >
              로그인
            </a>
          </li>
        </ul>
      </div>
    </header>
    """
  end
end
