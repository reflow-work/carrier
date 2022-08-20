defmodule CarrierWeb.Components.Flash do
  use Phoenix.Component

  def flash(assigns) do
    ~H"""
      <%= for {kind, message} <- @flash do %>
        <p class={kind_to_class(kind)} role="alert"
          phx-click="lv:clear-flash"
          phx-value-key={kind}><%= message %></p>
      <% end %>
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
