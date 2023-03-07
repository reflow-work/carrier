defmodule CarrierWeb.Components.SlackImgMetaData do
  use CarrierWeb, :component
  alias CarrierWeb.Components.Icon

  def card(assigns) do
    ~H"""
    <.trend_icon value={assigns.diff_value_raw} />
    <p class="text-slackImgGrey font-bold text-xs">
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
        <span class={value_color(@diff_value_raw)}> 증가</span><span>했어요.</span>
        """

      assigns.diff_value_raw < 0 ->
        ~H"""
        <span>지난 주 대비 </span>
        <span class={value_color(@diff_value_raw)}>
          <%= @diff_value_raw %>
        </span>
        <span>만큼 </span>
        <span class={value_color(@diff_value_raw)}> 감소</span><span>했어요.</span>
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
    case assigns.diff_value_percentage do
      0 ->
        ~H"""
        <span></span>
        """

      :negative_infinity ->
        ~H"""
        <span>비율을 계산할 수 없어요.</span>
        """

      :infinity ->
        ~H"""
        <span>비율을 계산할 수 없어요.</span>
        """

      :nan ->
        ~H"""
        <span>비율을 계산할 수 없어요.</span>
        """

      n ->
        cond do
          n > 0 ->
            ~H"""
            <span class={value_color(@diff_value_percentage)}>
              <%= "#{@diff_value_percentage}%" %>
            </span>
            <span> 올랐어요.</span>
            """

          n < 0 ->
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
end
