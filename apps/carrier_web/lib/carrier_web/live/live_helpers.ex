defmodule CarrierWeb.LiveHelpers do
  import Phoenix.Component
  alias Phoenix.LiveView.JS

  @doc """
  Renders a live component inside a modal.

  The rendered modal receives a `:return_to` option to properly update
  the URL when the modal is closed.

  ## Examples

      <.modal id="modal-1" data-show-modal}>
        <.live_component
          module={AppWeb.UserLive.FormComponent}
          id={@user.id || :new}
          title={@page_title}
          action={@live_action}
          user: @user
        />
      </.modal>
  """
  def modal(assigns) do
    ~H"""
    <div
      id={@id}
      class="hidden modal modal-open fade-in"
      data-show-modal={show_modal(@id)}
      data-hide-modal={hide_modal(@id)}
    >
      <div
        class="modal-content modal-box w-auto max-w-full fade-in-scale"
        phx-click-away={JS.dispatch("click", to: "##{@id}.close")}
        phx-window-keydown={JS.dispatch("click", to: "##{@id}.close")}
        phx-key="escape"
      >
        <.link href="#" class="close phx-modal-close" phx-click={hide_modal(@id)}>✖</.link>

        <%= render_slot(@inner_block) %>
      </div>
    </div>
    """
  end

  def show_modal(id, js \\ %JS{}) do
    js
    |> JS.show(to: "##{id}", display: "flex")
    |> JS.show(to: "##{id}.modal-content")
  end

  def hide_modal(id, js \\ %JS{}) do
    js
    |> JS.hide(to: "##{id}", transition: "fade-out")
    |> JS.hide(to: "##{id}.modal-content", transition: "fade-out-scale")
  end

  def format_number(s) do
    case Carrier.Core.Cldr.Number.to_string(s) do
      {:ok, n} -> n
      {:error, _msg} -> "0"
    end
  end

  def current_datetime!(timezone) do
    DateTime.now!(timezone)
  end

  def js_exec(js \\ %JS{}, to, call, args) do
    JS.dispatch(js, "js:exec", to: to, detail: %{call: call, args: args})
  end
end
