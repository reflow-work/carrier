defmodule LandingHeaderComponent do
  use Phoenix.LiveComponent
  alias Carrier.Const

  import CarrierWeb.AnalyticsHelper

  @impl true
  def render(assigns) do
    ~H"""
    <header class="header border-b z-10 w-full fixed bg-white">
      <div class="landing-container flex justify-between items-center">
        <a
          class="float-left py-4 cursor-pointer"
          phx-target={@myself}
          phx-click="click_link"
          phx-value-name="logo_on_header"
          phx-value-to="/"
        >
          <CarrierWeb.Components.Icon.logo_with_beta class="w-32" />
        </a>

        <div class="flex items-center">
          <ul class="flex-row hidden md:flex md:mr-4">
            <%= if Carrier.Setting.get_feature_flag_value("blog") do %>
              <li>
                <a
                  class="font-bold cursor-pointer text-base !text-black px-4"
                  phx-target={@myself}
                  phx-click="click_link"
                  phx-value-name="pricing_on_header"
                  phx-value-to="/blog"
                >
                  블로그
                </a>
              </li>
            <% end %>
            <li>
              <a
                class="font-bold cursor-pointer text-base !text-black px-4"
                phx-target={@myself}
                phx-click="click_link"
                phx-value-name="pricing_on_header"
                phx-value-to="/pricing"
              >
                가격 정책
              </a>
            </li>
            <li>
              <a
                class="font-bold cursor-pointer text-base !text-black px-4"
                phx-target={@myself}
                phx-click="click_link"
                phx-value-name="login_on_header"
                phx-value-to="/login"
              >
                로그인
              </a>
            </li>
          </ul>
          <button
            class="button button-primary"
            type="button"
            phx-target={@myself}
            phx-click="click_demo_button"
          >
            데모 신청하기
          </button>

          <label class="cursor-pointer pl-3 md:hidden" for="hamburger-button">
            <CarrierWeb.Components.Icon.menu class="w-8" />
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
              phx-click="click_link"
              phx-value-name="pricing_on_header"
              phx-value-to="/pricing"
            >
              가격 정책
            </a>
          </li>
          <li>
            <a
              class="w-full block font-bold cursor-pointer px-4 py-4 text-sm"
              phx-target={@myself}
              phx-click="click_link"
              phx-value-name="login_on_header"
              phx-value-to="/login"
            >
              로그인
            </a>
          </li>
        </ul>
      </div>
    </header>
    """
  end

  @impl true
  def handle_event("click_link", %{"name" => name, "to" => to}, socket) do
    socket =
      socket
      |> log_event(name, %{
        page_name: "landing"
      })

    {:noreply, push_navigate(socket, to: to)}
  end

  @impl true
  def handle_event("click_demo_button", _params, socket) do
    url = Const.get(:demo_call_url)

    socket
    |> log_event("click_demo_on_header", %{
      page_name: "landing"
    })

    {:noreply, push_event(socket, "new-window", %{url: url, target: "_blank"})}
  end
end
