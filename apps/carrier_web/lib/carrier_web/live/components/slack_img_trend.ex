defmodule CarrierWeb.Components.SlackImgTrend do
  use CarrierWeb, :component
  alias CarrierWeb.Components.Icon

  def trend_icon(assigns) do
    ~H"""
    <%= if @value >= 0 do %>
      <Icon.trend_up class="w-5 h-5" />
    <% else %>
      <Icon.trend_down class="w-5 h-5" />
    <% end %>
    """
  end

  def trend_text(assigns) do
    ~H"""
    <%= if @value > 0 do %>
      <span class={value_color(@value)}> 증가</span><span>하여</span>
    <% else %>
      <%= if @value < 0 do %>
        <span class={value_color(@value)}> 감소</span><span>하여</span>
      <% else %>
        <span>
          유지되어
        </span>
      <% end %>
    <% end %>
    """
  end

  defp value_color(value) when is_number(value) do
    case value do
      value when value > 0 -> "text-slackImgBlue"
      value when value < 0 -> "text-slackImgRed"
      _ -> ""
    end
  end

  defp value_color(_), do: ""
end
