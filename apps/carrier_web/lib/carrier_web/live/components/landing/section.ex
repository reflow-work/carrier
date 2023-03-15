defmodule CarrierWeb.Components.Landing.Section do
  use Phoenix.Component

  slot :inner_block, required: true
  attr :image_url, :string, required: true
  attr :image_position, :string, default: "right"
  attr :bg_color, :string, default: "bg-white"

  def feature(assigns) do
    ~H"""
    <section class={"#{@bg_color}"}>
      <div class="landing-container section grid grid-cols-12 gap-6 items-center">
        <div class="col-span-12 md:col-span-6 col-start-7 col-end-12">
          <%= render_slot(@inner_block) %>
        </div>
        <div class={"col-span-12 md:col-span-6 col-start-1 col-end-6 #{if @image_position == "left" do "order-first" end}"}>
          <img src={@image_url} class="w-full" />
        </div>
      </div>
    </section>
    """
  end
end
