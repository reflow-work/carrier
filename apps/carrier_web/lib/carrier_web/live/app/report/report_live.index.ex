defmodule CarrierWeb.App.ReportLive.Index do
  use CarrierWeb, :live_view
  use Carrier.{Integrations, Billing, Reports}
  alias Carrier.Core.{WeekdayHelper, TimeHelper, Nillable}
  alias Carrier.Roles.Role

  # TODO: remove it
  on_mount(CarrierWeb.DataTargetHook)
  on_mount(CarrierWeb.SubscriptionHook)

  @impl true
  def mount(params, session, socket) do
    socket =
      socket
      |> assign(:reports, [])
      |> assign(:active_subscription, nil)
      |> load_active_subscription()
      |> load_data_sources()

    socket =
      case connected?(socket) do
        true ->
          socket =
            socket
            |> load_reports()

          case length(socket.assigns.reports) < 1 do
            true -> socket |> push_navigate(to: ~p"/app/reports/new2")
            _ -> socket
          end

        false ->
          socket
      end

    socket =
      case params do
        %{"redirected" => "true"} ->
          push_event(socket, "smartlook_identify", %{
            "orgId" => session["org_id"],
            "userId" => session["user_id"]
          })

        _ ->
          socket
      end

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    socket =
      case socket.assigns.live_action do
        :index ->
          socket

        :delete ->
          report_id = params["id"] |> Obfuscatable.deobfuscate!(Report)

          socket
          |> assign(:report_id, report_id)
      end

    {:noreply, socket}
  end

  @impl true
  def handle_event("delete_report", _params, socket) do
    socket =
      socket
      |> delete_report(socket.assigns.report_id)

    {:noreply, socket}
  end

  defp load_reports(socket) do
    case Reports.list_reports() do
      {:ok, reports} ->
        socket |> assign(:reports, reports)
    end
  end

  defp delete_report(socket, report_id) do
    case Reports.delete_report(report_id) do
      {:ok, _deleted_report} ->
        socket
        |> update(:reports, fn reports -> reports |> Enum.reject(&(&1.id == report_id)) end)
        |> push_patch(to: ~p"/app/reports")

      {:error, reason} ->
        socket
        |> put_flash_for(:error, inspect(reason), timeout: :timer.seconds(3))
    end
  end

  defp triggered_at(%Report{interval: :hourly}, _timezone) do
    "매시간"
  end

  defp triggered_at(%Report{interval: :daily, trigger_time: trigger_time}, timezone) do
    TimeHelper.from_utc_time(trigger_time, timezone)
    |> Timex.format!("매일 {0h24}:{0m}")
  end

  defp triggered_at(
         %Report{interval: :weekly, trigger_weekday: trigger_weekday, trigger_time: trigger_time},
         timezone
       ) do
    weekday = WeekdayHelper.from_utc_weekday(trigger_weekday, trigger_time, timezone)
    weekday_name = WeekdayHelper.safe_format_weekday(weekday)

    TimeHelper.from_utc_time(trigger_time, timezone)
    |> Timex.format!("#{weekday_name} {0h24}:{0m}")
  end

  defp load_active_subscription(socket) do
    case Billing.fetch_active_subscription() do
      {:ok, subscription} ->
        socket |> assign(:active_subscription, subscription)

      _ ->
        socket
    end
  end

  defp load_data_sources(socket) do
    case Integrations.list_data_sources() do
      {:ok, data_sources} -> socket |> assign(:data_sources, data_sources)
      _ -> socket
    end
  end

  # TODO: remove nil case

  defp disabled_new_report_button(nil, _reports), do: false

  defp disabled_new_report_button(subscription, reports) do
    role = subscription.plan.role

    case role |> Role.report_max_count() do
      nil -> false
      report_max_count -> report_max_count <= Enum.count(reports)
    end
  end

  # TODO: preload 로 변경
  defp data_source(data_sources, report) do
    data_sources
    |> Enum.find(&(&1.id == report.data_source_info.data_source_id))
  end
end
