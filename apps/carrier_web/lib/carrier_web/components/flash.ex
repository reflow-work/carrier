defmodule CarrierWeb.Components.Flash do
  use Phoenix.Component

  def flash(assigns) do
    ~H"""
    <div class="toast toast-top toast-center">
      <%= for {kind, message} <- @flash do %>
        <div class={kind_to_class(kind)} role="alert" phx-click="lv:clear-flash" phx-value-key={kind}>
          <span class="dot"></span><%= message %>
        </div>
      <% end %>
    </div>
    """
  end

  defp kind_to_class(kind) do
    type =
      case kind do
        "info" -> "info"
        "warn" -> "warning"
        "error" -> "danger"
      end

    "alert alert-#{type}"
  end
end
