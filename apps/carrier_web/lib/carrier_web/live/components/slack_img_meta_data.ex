defmodule CarrierWeb.Components.SlackImgMetaData do
  use CarrierWeb, :component
  alias CarrierWeb.Components.Icon

  def card(assigns) do
    ~H"""
    <p class="text-slackImgGrey font-bold">
      <%= first_line(assigns) %>
      <br />
      <%= second_line(assigns) %>
    </p>
    """
  end

  def trend_icon(assigns) do
    ~H"""
    <%= if @value > 0 do %>
      <Icon.trend_up class="w-5 h-5" />
    <% else %>
      <%= if @value < 0 do %>
        <Icon.trend_down class="w-5 h-5" />
      <% else %>
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

  defp first_line(assigns) do
    cond do
      assigns.diff_value_raw > 0 ->
        ~H"""
        <span>지난 주 대비 </span>
        <span class={value_color(@diff_value_raw)}>
          <%= @diff_value_raw %>
        </span>
        <span>만큼 </span>
        <span class={value_color(@diff_value_raw)}> 증가</span><span>하여</span>
        """

      assigns.diff_value_raw < 0 ->
        ~H"""
        <span>지난 주 대비 </span>
        <span class={value_color(@diff_value_raw)}>
          <%= @diff_value_raw %>
        </span>
        <span>만큼 </span>
        <span class={value_color(@diff_value_raw)}> 감소</span><span>하여</span>
        """

      assigns.diff_value_raw == 0 ->
        ~H"""
        <span>지난 주 대비 동일해요.</span>
        """

      true ->
        ~H"""
        <span>오류 - 잘못된 값이 입력되었습니다.</span>
        """
    end
  end

  defp second_line(assigns) do
    cond do
      assigns.diff_value_percentage == 0 ->
        ~H"""
        <span></span>
        """

      assigns.diff_value_percentage == :negative_infinity ->
        ~H"""
        <span>데이터에 문제가 있어 값을 계산할 수 없습니다.</span>
        """

      assigns.diff_value_percentage == :infinity ->
        ~H"""
        <span>데이터에 문제가 있어 값을 계산할 수 없습니다.</span>
        """

      assigns.diff_value_percentage == :nan ->
        ~H"""
        <span>데이터에 문제가 있어 값을 계산할 수 없습니다.</span>
        """

      assigns.diff_value_percentage > 0 ->
        ~H"""
        <span class={value_color(@diff_value_percentage)}>
          <%= "#{@diff_value_percentage}%" %>
        </span>
        <span> 올랐어요.</span>
        """

      assigns.diff_value_percentage < 0 ->
        ~H"""
        <span class={value_color(@diff_value_percentage)}>
          <%= "#{@diff_value_percentage}%" %>
        </span>
        <span> 떨어졌어요. </span>
        """

      true ->
        ~H"""
        <span>오류 - 잘못된 값이 입력되었습니다.</span>
        """
    end
  end
end
