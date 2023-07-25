defmodule CarrierWeb.Components.QueryChecker do
  use CarrierWeb, :component

  def checker(assigns) do
    assigns = assign_new(assigns, :checked, fn -> false end)
    assigns = assign_new(assigns, :class, fn -> "" end)

    ~H"""
    <div class={"#{assigns.class} flex items-center shadow py-3 px-3 rounded border-l-8 #{if @checked, do: "border-l-green-600", else: "border-l-red-600"}"}>
      <div class="mr-3 text-base">
        <%= if @checked do %>
          <Icon.check_circle class="w-6 h-6 text-green-600" />
        <% else %>
          <Icon.x_circle class="w-6 h-6 text-red-600" />
        <% end %>
      </div>
      <div>
        <%= render_slot(@inner_block) %>
      </div>
    </div>
    """
  end
end
