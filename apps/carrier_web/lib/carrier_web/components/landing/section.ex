defmodule CarrierWeb.Components.Landing.Section do
  use Phoenix.Component

  slot :inner_block, required: true
  attr :image_url, :string, required: true
  attr :image_position, :string, default: "right"
  attr :bg_color, :string, default: "bg-white"

  def feature(assigns) do
    ~H"""
    <section class={"#{@bg_color}"}>
      <div class="landing-container section flex grid grid-cols-12 gap-6 items-center">
        <div class={"col-span-12 md:col-span-6 #{if @image_position == "right" do "md:col-start-1 md:row-start-1" end}"}>
          <%= render_slot(@inner_block) %>
        </div>
        <div class={"col-span-12 md:col-span-6 order-first mb-6 md:mb-0 #{if @image_position == "right" do "md:order-end md:col-start-7" end}"}>
          <img src={@image_url} class="w-full" />
        </div>
      </div>
    </section>
    """
  end
end
