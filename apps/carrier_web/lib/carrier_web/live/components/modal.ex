defmodule CarrierWeb.Components.Modal do
  use Phoenix.Component

  def confirm(assigns) do
    ~H"""
    <div>
      <div class="modal modal-open">
        <div class="modal-box">
          <h3 class="font-bold text-lg">
            <%= render_slot(@title) %>
          </h3>
          <div class="modal-action">
            <%= render_slot(@actions) %>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
