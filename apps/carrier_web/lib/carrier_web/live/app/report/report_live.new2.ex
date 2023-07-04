defmodule CarrierWeb.App.ReportLive.New2 do
  use CarrierWeb, :live_view
  use Carrier.{Integrations, Data, Reports, Setting}
  alias __MODULE__.Components
  alias __MODULE__.ReportParams
  alias CarrierWeb.Components.DataSourceSelector
  alias Carrier.Core.{Nillable, Async, TimeHelper, WeekdayHelper}
  alias Doumi.Phoenix.Params

  on_mount(CarrierWeb.DataTargetHook)

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:action, nil)
      |> assign(:title, nil)
      |> assign(:report, nil)
      |> assign(:data_source_info, nil)
      |> assign(:data_target_info, nil)
      |> assign(:selected_data_source_id, nil)
      |> assign(:selected_data_source, nil)
      |> assign(:selected_data_target, socket.assigns.data_target)
      |> assign(:data_source_info_form, nil)
      |> assign(:data_target_info_form, nil)
      |> assign(:report_form, nil)
      |> assign(:valid?, false)

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _uri, %{assigns: %{live_action: :new}} = socket) do
    data_source_id =
      params["data_source_id"] |> Nillable.map(&Obfuscatable.deobfuscate!(&1, DataSource))

    report_form =
      ReportParams.to_form(
        %{
          interval: :daily
        },
        validate: false
      )

    socket =
      socket
      |> assign(:action, :new)
      |> assign(:title, "레포트 생성하기")
      |> assign(:selected_data_source_id, data_source_id)
      |> assign(:report_form, report_form)

    {:noreply, socket}
  end

  @impl true
  def handle_params(params, _uri, %{assigns: %{live_action: :edit}} = socket) do
    report_id = params["report_id"] |> Nillable.map(&Obfuscatable.deobfuscate!(&1, Report))

    socket = socket |> load_report(report_id)

    report = socket.assigns.report

    utc_trigger_time = report |> Map.get(:trigger_time)
    utc_trigger_weekday = report |> Map.get(:trigger_weekday)

    zoned_trigger_time =
      utc_trigger_time |> Nillable.map(&TimeHelper.from_utc_time(&1, report.timezone))

    zoned_trigger_weekday =
      utc_trigger_weekday
      |> Nillable.map(&WeekdayHelper.from_utc_weekday(&1, utc_trigger_time, report.timezone))

    report_form =
      ReportParams.to_form(
        report
        |> Map.from_struct()
        |> Map.put(:trigger_time, zoned_trigger_time)
        |> Map.put(:trigger_weekday, zoned_trigger_weekday),
        validate: false
      )

    data_source_info = report.data_source_info |> Map.from_struct()
    data_target_info = report.data_target_info |> Map.from_struct()

    socket =
      socket
      |> assign(:action, :edit)
      |> assign(:title, "레포트 수정하기")
      |> assign(:selected_data_source_id, data_source_info.data_source_id)
      |> assign(:data_source_info, data_source_info)
      |> assign(:data_target_info, data_target_info)
      |> assign(:report_form, report_form)

    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <section class="page-container">
      <.page_header icon="📊" title={@title} />

      <ol class="mt-8 flex flex-row items-center w-full space-x-4 text-sm font-medium text-center">
        <li class="flex items-center text-primary">
          <span class="flex items-center justify-center w-5 h-5 text-sm mr-1">
            1.
          </span>
          데이터 소스 선택 <.icon class="w-4 h-4 ml-4" name="hero-chevron-double-right-mini" />
        </li>
        <li class="flex items-center">
          <span class="flex items-center justify-center w-5 h-5 text-sm mr-1">
            2.
          </span>
          대시보드 데이터 설정 <.icon class="w-4 h-4 ml-4" name="hero-chevron-double-right-mini" />
        </li>
        <li class="flex items-center">
          <span class="flex items-center justify-center w-5 h-5 text-sm mr-1">
            3.
          </span>
          리포트 설정 <.icon class="w-4 h-4 ml-4" name="hero-chevron-double-right-mini" />
        </li>
        <li class="flex items-center">
          <span class="flex items-center justify-center w-5 h-5 text-sm mr-1">
            4.
          </span>
          슬랙 설정
        </li>
      </ol>

      <.live_component
        module={DataSourceSelector}
        id="data_source_selector"
        org={@org}
        selected_data_source_id={@selected_data_source_id}
        disabled={@live_action != :new}
        title="1. 데이터 소스 선택"
      />

      <div :if={@selected_data_source}>
        <Components.data_transformer
          data_source={@selected_data_source}
          data_source_info={@data_source_info}
        />
        <Components.report_configurer report_form={@report_form} valid?={@valid?} />
        <Components.data_target_selector
          data_targets={@data_targets}
          selected_data_target={@selected_data_target}
          onselect="select_data_target"
          disabled={@live_action != :new}
        />
        <Components.data_target_configurer
          data_target={@selected_data_target}
          data_target_info={@data_target_info}
        />
        <div>
          <.simple_form for={%{}} phx-submit="create_report">
            <div class="mt-8 space-x-4">
              <.button
                type="button"
                style={:outline}
                disabled={!@valid?}
                phx-click={
                  js_log_event("click_send_test_report", %{page_name: "report_new"})
                  |> JS.push("send_test_report")
                }
              >
                테스트 발송
              </.button>
              <.button
                type="submit"
                disabled={!@valid? || @selected_data_source.demo}
                phx-disable-with="생성 중"
                phx-click={js_log_event("click_create_report", %{page_name: "report_new"})}
              >
                리포트 저장 <span :if={@selected_data_source.demo}>(Demo 데이터 소스는 저장 불가)</span>
              </.button>
            </div>
          </.simple_form>
        </div>
      </div>
    </section>
    """
  end

  @impl true
  def handle_event("select_data_target", %{"data_target_id" => data_target_id_str}, socket) do
    data_target_id = data_target_id_str |> String.to_integer()

    selected_data_target =
      socket.assigns.data_targets
      |> Enum.find(&(&1.id == data_target_id))

    socket =
      socket
      |> assign(:selected_data_target, selected_data_target)

    {:noreply, socket}
  end

  @impl true
  def handle_event("validate_report", %{"report" => report_input}, socket) do
    socket =
      socket
      |> update_report_form(report_input)
      |> update_valid()

    {:noreply, socket}
  end

  @impl true
  def handle_event("create_report", _, socket) do
    report = socket.assigns.report_form |> Params.to_map()

    zoned_trigger_time = report |> Map.get(:trigger_time)
    zoned_trigger_weekday = report |> Map.get(:trigger_weekday)

    utc_trigger_time =
      zoned_trigger_time |> Nillable.map(&TimeHelper.to_utc_time(&1, report.timezone))

    utc_trigger_weekday =
      zoned_trigger_weekday
      |> Nillable.map(&WeekdayHelper.to_utc_weekday(&1, zoned_trigger_time, report.timezone))

    report =
      report
      |> Map.put(:trigger_time, utc_trigger_time)
      |> Map.put(:trigger_weekday, utc_trigger_weekday)

    data_source_info = socket.assigns.data_source_info_form |> Params.to_map()
    data_target_info = socket.assigns.data_target_info_form |> Params.to_map()

    params =
      report
      |> Map.merge(%{
        data_source_info: data_source_info,
        data_target_info: data_target_info
      })

    socket =
      socket.assigns.action
      |> case do
        :new -> Reports.create_report(params)
        :edit -> Reports.update_report(socket.assigns.report.id, params)
      end
      |> case do
        {:ok, _report} ->
          socket
          |> put_flash_for(:info, "\"#{report.name}\" 레포트가 저장되었습니다.", timeout: :timer.seconds(3))
          |> push_navigate(to: ~p"/app/reports")

        {:error, error} ->
          Logger.error(inspect(error))

          socket |> put_flash_for(:error, "레포트 저장에 실패하였습니다.", timeout: :timer.seconds(3))
      end

    {:noreply, socket}
  end

  @impl true
  def handle_event("send_test_report", _params, socket) do
    report = socket.assigns.report_form |> Params.to_map()
    data_source_info = socket.assigns.data_source_info_form |> Params.to_map()
    data_target_info = socket.assigns.data_target_info_form |> Params.to_map()

    params =
      report
      |> Map.merge(%{
        data_source_info: data_source_info,
        data_target_info: data_target_info,
        datetime: DateTime.utc_now(),
        timezone: socket.assigns.timezone
      })

    Async.run(fn ->
      with {:ok, threads} <- Data.prepare_threads(params),
           :ok <- Data.send_messages(report, threads, data_target_info) do
        :ok
      else
        {:error, error} ->
          Logger.error("Failed to send test report: #{inspect(error)}")

          {:error, error}
      end
    end)

    socket =
      socket
      |> put_flash_for(:info, "선택한 쿼리 결과에 대한 슬랙 메시지가 발송되었습니다! 😊", timeout: :timer.seconds(3))

    {:noreply, socket}
  end

  @impl true
  def handle_event(
        "data_target_created",
        %{"data_target_id" => obfuscated_data_target_id},
        socket
      ) do
    data_target_id = Carrier.Obfuscatable.deobfuscate!(obfuscated_data_target_id, DataTarget)

    {:ok, data_target} = Integrations.fetch_data_target(data_target_id)

    socket =
      socket
      |> update(:data_targets, &[data_target | &1])
      |> assign(:selected_data_target, data_target)

    {:noreply, socket}
  end

  @impl true
  def handle_info({:data_source_selected, selected_data_source}, socket) do
    socket =
      socket
      |> assign(:selected_data_source, selected_data_source)

    socket =
      case socket.assigns.live_action do
        :new ->
          socket
          |> push_patch(
            to: ~p"/app/reports/new2?data_source_id=#{selected_data_source}",
            replace: true
          )

        :edit ->
          socket
      end

    {:noreply, socket}
  end

  @impl true
  def handle_info({:update, {:data_source_info_form, data_source_info_form}}, socket) do
    socket =
      socket
      |> assign(:data_source_info_form, data_source_info_form)
      |> update_valid()

    {:noreply, socket}
  end

  @impl true
  def handle_info({:update, {:data_target_info_form, data_target_info_form}}, socket) do
    socket =
      socket
      |> assign(:data_target_info_form, data_target_info_form)
      |> update_valid()

    {:noreply, socket}
  end

  @impl true
  def handle_info(message, socket) do
    case handle_async_assigns(message, socket) do
      {:ok, socket} ->
        {:noreply, socket}

      _ ->
        {:noreply, socket}
    end
  end

  defp load_report(socket, report_id) do
    case Reports.fetch_report(report_id) do
      {:ok, report} ->
        socket |> assign(:report, report)

      {:error, reason} ->
        socket
        |> put_flash_for(:error, "레포트를 불러오는데 실패하였습니다. (#{inspect(reason)})",
          timeout: :timer.seconds(3)
        )
        |> push_navigate(to: ~p"/app/reports")
    end
  end

  defp update_report_form(socket, report_input) do
    report_input =
      %{
        "org_id" => socket.assigns.org.org_id,
        "user_id" => socket.assigns.user.id,
        "timezone" => socket.assigns.timezone
      }
      |> Map.merge(report_input)

    report_form = ReportParams.to_form(report_input)

    socket
    |> assign(:report_form, report_form)
  end

  defp update_valid(socket) do
    valid? =
      [
        socket.assigns.data_source_info_form,
        socket.assigns.data_target_info_form,
        socket.assigns.report_form
      ]
      |> Enum.all?(&valid?/1)

    socket
    |> assign(:valid?, valid?)
  end

  defp valid?(%Phoenix.HTML.Form{source: source}), do: source.valid?
  defp valid?(_), do: false
end
