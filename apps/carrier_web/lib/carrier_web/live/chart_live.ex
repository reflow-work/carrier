defmodule CarrierWeb.ChartLive do
  use CarrierWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    schedule_update()
    {:ok, socket}
  end

  @impl true
  def handle_info(:update, socket) do
    schedule_update()
    {:noreply, socket |> push_event("votes", %{votes: get_votes})}
  end

  @impl true
  def handle_event("next", _, socket) do
    {:noreply, socket |> push_event("votes", %{votes: get_votes})}
  end

  defp schedule_update, do: self() |> Process.send_after(:update, 5000)
  defp get_votes, do: 1..7 |> Enum.map(fn _ -> :rand.uniform(100) end)
end
