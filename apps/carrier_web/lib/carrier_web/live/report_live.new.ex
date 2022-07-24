defmodule CarrierWeb.ReportLive.New do
  use CarrierWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.form let={f} for={:report} id="report_form" phx-hook="ReportForm">
        <%= textarea(f, :sql_template, class: "textarea textarea-bordered", placeholder: "SQL here") %>

        <%= submit "test", type: "button", name: "test" %>
        <%= submit "analyze", type: "button", name: "analyze" %>
      </.form>
    </div>
    """
  end

  @impl true
  def handle_event("test", params, socket) do
    params |> parse_form_data() |> IO.inspect()

    {:noreply, socket}
  end

  @impl true
  def handle_event("analyze", params, socket) do
    params |> parse_form_data() |> IO.inspect()

    {:noreply, socket}
  end

  defp parse_form_data(form_data) do
    form_data
    |> Enum.reduce(%{}, fn {key, value}, map ->
      [key0, key1] = parse_form_data_key(key)

      map |> put_in([Access.key(key0, %{}), key1], value)
    end)
  end

  defp parse_form_data_key(key) do
    key |> String.split(["[", "]"], trim: true)
  end
end
