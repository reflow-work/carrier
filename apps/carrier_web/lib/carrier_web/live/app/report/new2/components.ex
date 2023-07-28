defmodule CarrierWeb.App.ReportLive.New2.Components do
  use CarrierWeb, :component
  use Carrier.Integrations
  import Carrier.Data.Source.RDB.Guard

  embed_templates "*"

  attr :data_source, :any, required: true
  attr :data_source_info, :any

  def data_transformer(assigns) do
    case assigns.data_source do
      nil ->
        empty_data_transformer(assigns)

      %DataSource{source: source} ->
        module =
          case source do
            source when is_rdb_source(source) ->
              CarrierWeb.App.ReportLive.New2.RDBDataTransformerOld

            :tableau ->
              CarrierWeb.App.ReportLive.New2.TableauDataTransformer

            :redash ->
              CarrierWeb.App.ReportLive.New2.RedashDataTransformer
          end

        assigns =
          assigns
          |> assign(:module, module)

        ~H"""
        <.live_component
          module={@module}
          id="data_transformer"
          data_source={@data_source}
          data_source_info={@data_source_info}
        />
        """

      _ ->
        ~H"""
        Not implemented
        """
    end
  end

  attr :data_targets, :list, required: true
  attr :selected_data_target, :any
  attr :onselect, :any, required: true
  attr :disabled, :boolean, required: true

  def data_target_selector(assigns) do
    case assigns.selected_data_target do
      nil ->
        ~H"""
        <div>
          <.card_container>
            <.card>
              <div>
                <.card_title title="Slack 발송 설정하기" />
              </div>

              <div>
                <.button
                  :if={!@disabled}
                  id="new_data_target_button"
                  type="button"
                  phx-hook="Popup"
                  data-popup-url={
                    CarrierWeb.Helpers.SlackHelper.get_redirect_uri(nil, true)
                    |> Carrier.External.SlackAPI.OAuth.generate_url()
                  }
                  data-callback-event="data_target_created"
                  phx-click={
                    js_log_event("click_connect_slack", %{page_name: "report_new"})
                    |> JS.dispatch("open_popup")
                  }
                  class="!bg-white text-black border w-lg flex items-center w-48 justify-center"
                >
                  <svg
                    xmlns="http://www.w3.org/2000/svg"
                    style="height:16px;width:16px;margin-right:12px"
                    viewBox="0 0 122.8 122.8"
                  >
                    <path
                      d="M25.8 77.6c0 7.1-5.8 12.9-12.9 12.9S0 84.7 0 77.6s5.8-12.9 12.9-12.9h12.9v12.9zm6.5 0c0-7.1 5.8-12.9 12.9-12.9s12.9 5.8 12.9 12.9v32.3c0 7.1-5.8 12.9-12.9 12.9s-12.9-5.8-12.9-12.9V77.6z"
                      fill="#e01e5a"
                    >
                    </path>
                    <path
                      d="M45.2 25.8c-7.1 0-12.9-5.8-12.9-12.9S38.1 0 45.2 0s12.9 5.8 12.9 12.9v12.9H45.2zm0 6.5c7.1 0 12.9 5.8 12.9 12.9s-5.8 12.9-12.9 12.9H12.9C5.8 58.1 0 52.3 0 45.2s5.8-12.9 12.9-12.9h32.3z"
                      fill="#36c5f0"
                    >
                    </path>
                    <path
                      d="M97 45.2c0-7.1 5.8-12.9 12.9-12.9s12.9 5.8 12.9 12.9-5.8 12.9-12.9 12.9H97V45.2zm-6.5 0c0 7.1-5.8 12.9-12.9 12.9s-12.9-5.8-12.9-12.9V12.9C64.7 5.8 70.5 0 77.6 0s12.9 5.8 12.9 12.9v32.3z"
                      fill="#2eb67d"
                    >
                    </path>
                    <path
                      d="M77.6 97c7.1 0 12.9 5.8 12.9 12.9s-5.8 12.9-12.9 12.9-12.9-5.8-12.9-12.9V97h12.9zm0-6.5c-7.1 0-12.9-5.8-12.9-12.9s5.8-12.9 12.9-12.9h32.3c7.1 0 12.9 5.8 12.9 12.9s-5.8 12.9-12.9 12.9H77.6z"
                      fill="#ecb22e"
                    >
                    </path>
                  </svg>
                  슬랙 연동하기
                </.button>
              </div>
            </.card>
          </.card_container>
        </div>
        """

      # :later ->
      #   ~H"""
      #   <div>
      #     <.card_container>
      #       <.card>
      #         <div>
      #           <.card_title title="데이터 타겟" />
      #         </div>
      #         <.simple_form for={%{}} phx-change={@onselect}>
      #           <div class="flex items-center">
      #             <.input
      #               class="max-w-md flex-1"
      #               type="select"
      #               name="data_target_id"
      #               prompt="데이터 타겟을 선택해주세요"
      #               options={data_target_options(@data_targets)}
      #               value={@selected_data_target |> Nillable.map(& &1.id) |> Nillable.fallback("")}
      #             />
      #             <.button
      #               :if={!@disabled}
      #               id="new_data_target_button"
      #               type="button"
      #               class="ml-2"
      #               phx-hook="Popup"
      #               data-popup-url={url(~p"/app/data-targets/new?popup=true")}
      #               data-callback-event="data_target_created"
      #               phx-click={JS.dispatch("open_popup")}
      #             >
      #               새 데이터 타겟 추가
      #             </.button>
      #           </div>
      #         </.simple_form>
      #       </.card>
      #     </.card_container>
      #   </div>
      #   """

      _ ->
        ~H"""
        <div></div>
        """
    end
  end

  # defp data_target_options(data_targets) do
  #   data_targets
  #   |> Enum.map(fn %DataTarget{id: id, service_name: service_name} -> {service_name, id} end)
  # end

  attr :data_target, :any
  attr :data_target_info, :any

  def data_target_configurer(assigns) do
    case assigns.data_target do
      %DataTarget{service_name: :slack} ->
        ~H"""
        <.live_component
          module={CarrierWeb.App.ReportLive.New2.SlackConfigurer}
          id="slack_configurer"
          data_target={@data_target}
          data_target_info={@data_target_info}
        />
        """

      _ ->
        ~H"""
        <div></div>
        """
    end
  end

  attr :report_form, :any, required: true
  attr :valid?, :boolean, required: true

  def report_configurer(assigns) do
    ~H"""
    <div>
      <.card_container>
        <.card>
          <.card_title title="3. 리포트 설정" />
          <div class="max-w-md">
            <.simple_form for={@report_form} phx-change="validate_report">
              <.input
                type="text"
                field={@report_form[:name]}
                label="리포트 이름"
                label_align={:left}
                placeholder="데일리 유저 지표"
              />
              <.input
                type="hidden"
                field={@report_form[:text]}
                label="리포트 텍스트"
                phx-hook="TrixEditor"
              />
              <div id={"#{@report_form[:text].id}-editor"} phx-update="ignore">
                <trix-editor input={@report_form[:text].id}></trix-editor>
              </div>
              <.input
                type="select"
                field={@report_form[:interval]}
                label="발송 주기"
                label_align={:left}
                options={interval_options()}
              />
              <.input
                class={@report_form[:interval].value != :weekly && "hidden"}
                type="select"
                field={@report_form[:trigger_weekday]}
                label="발송 요일"
                label_align={:left}
                options={trigger_weekday_options()}
                value={@report_form[:trigger_weekday].value}
              />
              <.input
                class={@report_form[:interval].value not in [:daily, :weekly] && "hidden"}
                type="select"
                field={@report_form[:trigger_time]}
                label="발송 시간"
                label_align={:left}
                options={trigger_time_options()}
                value={@report_form[:trigger_time].value}
              />
              <.input
                type="select"
                name="timezone_disabled"
                label="타임존"
                label_align={:left}
                options={[
                  {format_timezone(@report_form[:timezone].value), @report_form[:timezone].value}
                ]}
                value={@report_form[:timezone].value}
                disabled
              />
              <.input type="hidden" field={@report_form[:timezone]} />
            </.simple_form>
          </div>
        </.card>
      </.card_container>
    </div>
    """
  end

  defp interval_options() do
    [
      {"매시간", :hourly},
      {"매일", :daily},
      {"매주", :weekly}
    ]
  end

  defp trigger_time_options() do
    [
      {"자정", "00:00:00"},
      {"오전 1시", "01:00:00"},
      {"오전 2시", "02:00:00"},
      {"오전 3시", "03:00:00"},
      {"오전 4시", "04:00:00"},
      {"오전 5시", "05:00:00"},
      {"오전 6시", "06:00:00"},
      {"오전 7시", "07:00:00"},
      {"오전 8시", "08:00:00"},
      {"오전 9시", "09:00:00"},
      {"오전 10시", "10:00:00"},
      {"오전 11시", "11:00:00"},
      {"정오", "12:00:00"},
      {"오후 1시", "13:00:00"},
      {"오후 2시", "14:00:00"},
      {"오후 3시", "15:00:00"},
      {"오후 4시", "16:00:00"},
      {"오후 5시", "17:00:00"},
      {"오후 6시", "18:00:00"},
      {"오후 7시", "19:00:00"},
      {"오후 8시", "20:00:00"},
      {"오후 9시", "21:00:00"},
      {"오후 10시", "22:00:00"},
      {"오후 11시", "23:00:00"}
    ]
  end

  defp trigger_weekday_options() do
    [
      {"월요일", 1},
      {"화요일", 2},
      {"수요일", 3},
      {"목요일", 4},
      {"금요일", 5},
      {"토요일", 6},
      {"일요일", 7}
    ]
  end
end
