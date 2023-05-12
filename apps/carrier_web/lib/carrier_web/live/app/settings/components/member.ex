defmodule CarrierWeb.App.SettingsLive.Components.Member do
  use CarrierWeb, :live_component
  alias Carrier.Accounts

  @impl true
  def mount(socket) do
    socket =
      socket
      |> assign(:users, [])
      |> assign(:is_show_modal, false)
      |> assign(:invite_link, nil)
      |> load_users()

    {:ok, socket}
  end

  @impl true
  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> load_invite_link(assigns.user.org)

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex-1">
      <.card_container class="space-y-4">
        <.card>
          <div class="flex justify-between">
            <.card_title title="멤버 관리" />
            <button
              phx-click="toggle_modal"
              phx-target={@myself}
              class={[
                "btn",
                "btn-primary"
              ]}
            >
              초대하기
            </button>
          </div>

          <section class="mt-6">
            <div class="overflow-x-auto">
              <table class="table w-full">
                <thead>
                  <tr>
                    <th>이메일</th>
                    <th>가입일</th>
                  </tr>
                </thead>
                <tbody>
                  <%= for user <- @users do %>
                    <tr class="hover">
                      <td><%= user.email %></td>
                      <td><%= user.signed_at |> format_date() %></td>
                    </tr>
                  <% end %>
                </tbody>
              </table>
            </div>
          </section>
        </.card>
      </.card_container>

      <%= if @is_show_modal do %>
        <CarrierWeb.Components.Modal.confirm>
          <:title>
            초대하기
          </:title>
          <div>
            초대 링크 👇
            <div
              id="invite-link-container"
              class="flex items-center mt-1"
              data-text={@invite_link}
              phx-click={JS.show(to: "#copied")}
              phx-hook="ClipboardCopy"
            >
              <div class="cursor-pointer underline text-blue-500">
                <%= @invite_link %>
              </div>
              <.icon name="hero-link" class="ml-1 cursor-pointer text-blue-500" />
              <div id="copied" class="hidden ml-1 text-sm text-description">- 복사 완료! 📑</div>
            </div>
          </div>
          <:actions>
            <a class="btn btn-primary btn-sm" phx-click="toggle_modal" phx-target={@myself}>닫기</a>
          </:actions>
        </CarrierWeb.Components.Modal.confirm>
      <% end %>
    </div>
    """
  end

  @impl true
  def handle_event("toggle_modal", _, socket) do
    socket = socket |> assign(:is_show_modal, !socket.assigns.is_show_modal)
    {:noreply, socket}
  end

  defp load_users(socket) do
    case Accounts.list_users() do
      {:ok, users} ->
        socket |> assign(:users, users)

      {:error, _} ->
        socket
    end
  end

  defp load_invite_link(socket, org) do
    socket
    |> assign(:invite_link, url(~p"/invite?token=#{org}"))
  end
end
