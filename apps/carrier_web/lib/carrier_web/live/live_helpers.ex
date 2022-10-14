defmodule CarrierWeb.LiveHelpers do
  import Phoenix.Component
  alias Phoenix.LiveView.JS
  alias Carrier.Core.Cldr

  @doc """
  Renders a live component inside a modal.

  The rendered modal receives a `:return_to` option to properly update
  the URL when the modal is closed.

  ## Examples

      <.modal return_to={Routes.user_index_path(@socket, :index)}>
        <.live_component
          module={AppWeb.UserLive.FormComponent}
          id={@user.id || :new}
          title={@page_title}
          action={@live_action}
          return_to={Routes.user_index_path(@socket, :index)}
          user: @user
        />
      </.modal>
  """
  def modal(assigns) do
    assigns = assign_new(assigns, :return_to, fn -> nil end)

    ~H"""
    <div id="modal" class="modal modal-open fade-in" phx-remove={hide_modal()}>
      <div
        id="modal-content"
        class="modal-box fade-in-scale"
        phx-click-away={JS.dispatch("click", to: "#close")}
        phx-window-keydown={JS.dispatch("click", to: "#close")}
        phx-key="escape"
      >
        <%= if @return_to do %>
          <.link patch={@return_to} id="close" class="phx-modal-close" phx-click={hide_modal()}>
            <CarrierWeb.Components.Icon.x_mark class="w-6 h-6" />
          </.link>
        <% else %>
          <.link id="close" href="#" class="phx-modal-close" phx-click={hide_modal()}>✖</.link>
        <% end %>

        <%= render_slot(@inner_block) %>
      </div>
    </div>
    """
  end

  def format_number(s) do
    case Number.to_string(s) do
      {:ok, n} -> n
      {:error, _msg} -> "0"
    end
  end

  defp hide_modal(js \\ %JS{}) do
    js
    |> JS.hide(to: "#modal", transition: "fade-out")
    |> JS.hide(to: "#modal-content", transition: "fade-out-scale")
  end
end
