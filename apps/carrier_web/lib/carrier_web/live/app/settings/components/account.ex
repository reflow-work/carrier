defmodule CarrierWeb.App.Settings.Components.Account do
  use CarrierWeb, :live_component

  @impl true
  def mount(socket) do
    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex-1">
      <.card_container class="space-y-4">
        <.card>
          <.card_title title="계정 정보" />
          <p><%= @user.email %></p>
        </.card>
        <.card>
          <.link href={~p"/logout"} phx-click="smartlook_anonymize" class="btn">
            로그아웃
          </.link>
        </.card>
      </.card_container>
    </div>
    """
  end
end
