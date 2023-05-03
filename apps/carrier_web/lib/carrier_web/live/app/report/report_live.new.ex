defmodule CarrierWeb.App.ReportLive.New do
  use CarrierWeb, :live_view
  use CarrierWeb.Params
  use Carrier.{Reports, Secrets}
  alias Carrier.Data.QueryData
  alias Carrier.Data.Source.Tableau
  alias Carrier.External.Slack
  alias Carrier.Core.{TimeHelper, Traversable, MapHelper, DateHelper, Nillable, MapHelper}
  alias CarrierWeb.Components.Empty
  alias CarrierWeb.Components.SlackImgMetaData
  alias CarrierWeb.Components.QueryChecker
  alias __MODULE__.{ReportParams, ReportTableau}

  on_mount(CarrierWeb.IntegrationHook)
  on_mount(CarrierWeb.DataSourceHook)

  @sample_sql_template """
  SELECT
  DATE([기준이 되는 날짜 컬럼]),
  SUM([보고 싶은 지표 컬럼1]) AS [컬럼1 이름],
  SUM([보고 싶은 지표 컬럼2]) AS [컬럼2 이름],
  SUM([보고 싶은 지표 컬럼3]) AS [컬럼3 이름]
  FROM [테이블 이름]
  WHERE DATE([기준이 되는 날짜 컬럼]) >= {{start}}
  AND DATE([기준이 되는 날짜 컬럼]) < {{end}}
  GROUP BY 1
  """
  @sql_template_by_maker """
  SELECT
  DATE(<%= date_column %>),
  <%= aggregation %>(<%= value_column %>) AS "<%= if value_column_name != "", do: value_column_name, else: value_column %>"
  FROM <%= table_name %>
  WHERE DATE(<%= date_column %>) >= {{start}}
  AND DATE(<%= date_column %>) < {{end}}
  GROUP BY 1
  """

  @query_date_length 28 + 7 + 28 + 1

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(_params, _uri, %{assigns: %{live_action: :new}} = socket) do
    socket =
      socket
      |> assign(:data_source, socket.assigns.data_sources |> List.first())
      |> init_common_assigns()
      |> init_assigns_by_data_source()
      |> init_assigns_by_integration()
      |> init_changeset()

    {:noreply, socket}
  end

  @impl true
  def handle_params(%{"id" => report_id_str}, _uri, %{assigns: %{live_action: :edit}} = socket) do
    report_id = report_id_str |> Crypto.deobfuscate!()

    socket =
      socket
      |> assign(:report_id, report_id)
      |> load_report()

    report = socket.assigns.report

    socket =
      socket
      |> assign(
        :data_source,
        socket.assigns.data_sources
        |> Enum.find(&(&1.id == report.data_source_info.data_source_id))
      )
      |> assign(
        :integeration,
        [socket.assigns.integration]
        |> Enum.find(&(&1.id == report.data_target_info.integration_id))
      )
      |> init_common_assigns()
      |> init_assigns_by_data_source()
      |> init_assigns_by_integration()
      |> assign(:report_name, report.name)
      |> assign(:channel_id, report.data_target_info.channel_id)
      |> assign(:channel_search_term, report.data_target_info.channel_name)

    hour =
      report.trigger_time
      |> TimeHelper.from_utc_time(socket.assigns.timezone)
      |> Map.get(:hour)
      |> to_string()

    socket =
      case socket.assigns.data_source.source do
        source when source in [:postgres, :mysql, :bigquery, :athena] ->
          with {:ok, %{columns: columns, data: data}} <-
                 QueryData.query(%{
                   org_id: report.org_id,
                   data_source_id: report.data_source_info.data_source_id,
                   sql_template: report.data_source_info.sql_template,
                   datetime: DateTime.utc_now(),
                   timezone: socket.assigns.timezone,
                   query_date_length: @query_date_length
                 }),
               {:ok, analyzed_data} <-
                 QueryData.analyze(data, %{
                   columns: columns,
                   period: report.data_source_info.period,
                   window_size: report.data_source_info.window_size,
                   comparing_period: report.data_source_info.comparing_period
                 }) do
            preview_data =
              QueryData.format_data_for_preview(%{columns: columns, data: analyzed_data})

            [_date_column | value_columns] = columns

            parsed_data =
              QueryData.refine_data_based_on_columns(
                %{columns: columns, data: analyzed_data},
                value_columns,
                report.data_source_info.window_size
              )

            socket
            |> assign(:sql_template, report.data_source_info.sql_template)
            |> assign(:query_result, %{columns: columns, data: data})
            |> assign(:preview, %{columns: columns, data: preview_data})
            |> assign(:query_result_by_columns, parsed_data)
            |> assign(:columns, value_columns)
            |> assign(:selected_columns, report.data_source_info.columns)
            |> add_draw_chart_events(parsed_data, report.data_source_info.columns)
            |> assign(
              :report_changeset,
              ReportParams.changeset(
                ReportParams.init_attrs(%{
                  org_id: socket.assigns.org.org_id,
                  user_id: socket.assigns.user.id,
                  name: report.name,
                  hour: hour,
                  trigger_time: report.trigger_time,
                  timezone: socket.assigns.timezone,
                  data_target_info: %{
                    integration_id: report.data_target_info.integration_id,
                    channel_id: report.data_target_info.channel_id,
                    channel_name: report.data_target_info.channel_name
                  },
                  data_source_info: %{
                    data_source_id: report.data_source_info.data_source_id,
                    source: report.data_source_info.source,
                    sql_template: report.data_source_info.sql_template,
                    period: report.data_source_info.period,
                    window_size: report.data_source_info.window_size,
                    comparing_period: report.data_source_info.comparing_period,
                    columns: report.data_source_info.columns
                  }
                })
              )
            )
          else
            _ ->
              socket
          end

        :tableau ->
          view =
            socket.assigns.tableau_views
            |> Enum.find(&(&1.id == report.data_source_info.view_id))

          {:ok, tableau_image_binary} =
            Tableau.get_view_image_binary(
              view.id,
              ConnInfo.to_credentials(socket.assigns.data_source.conn_info)
            )

          socket
          |> assign(:tableau_selected_view, view)
          |> assign(:tableau_view_search_term, view.full_name)
          |> assign(:tableau_image_binary, tableau_image_binary)
          |> assign(
            :report_changeset,
            ReportTableau.changeset(
              ReportTableau.init_attrs(%{
                org_id: socket.assigns.org.org_id,
                user_id: socket.assigns.user.id,
                name: report.name,
                hour: hour,
                trigger_time: report.trigger_time,
                timezone: socket.assigns.timezone,
                data_target_info: %{
                  integration_id: report.data_target_info.integration_id,
                  channel_id: report.data_target_info.channel_id,
                  channel_name: report.data_target_info.channel_name
                },
                data_source_info: %{
                  data_source_id: report.data_source_info.data_source_id,
                  source: report.data_source_info.source,
                  view_id: report.data_source_info.view_id,
                  view_full_name: report.data_source_info.view_full_name
                }
              })
            )
          )
      end
      |> assign(:data_loaded, true)

    {:noreply, socket}
  end

  @impl true
  def handle_event(
        "select_data_source",
        %{"data_source" => %{"id" => data_source_id_str}},
        socket
      ) do
    data_source_id = data_source_id_str |> String.to_integer()

    data_source =
      socket.assigns.data_sources
      |> Enum.find(&(&1.id == data_source_id))

    socket =
      socket
      |> assign(:data_source, data_source)
      |> init_assigns_by_data_source()
      |> init_changeset()

    {:noreply, socket}
  end

  @impl true
  def handle_event(
        "search_tableau_view",
        %{"tableau_view" => %{"tableau_view_search_term" => tableau_view_search_term}},
        socket
      ) do
    tableau_view_suggestions =
      case tableau_view_search_term |> String.trim() do
        "" ->
          []

        tableau_view_search_term ->
          regex = ~r/#{tableau_view_search_term}/i

          socket.assigns.tableau_views
          |> Enum.filter(&(&1.full_name =~ regex))
      end

    socket =
      socket
      |> assign(:tableau_view_suggestions, tableau_view_suggestions)

    {:noreply, socket}
  end

  @impl true
  def handle_event(
        "search_tableau_view",
        %{"value" => tableau_view_search_term},
        socket
      ) do
    tableau_view_suggestions =
      case tableau_view_search_term |> String.trim() do
        "" ->
          []

        tableau_view_search_term ->
          socket.assigns.tableau_views
          |> Enum.filter(&(&1.full_name =~ tableau_view_search_term))
      end

    socket =
      socket
      |> assign(:tableau_view_suggestions, tableau_view_suggestions)

    {:noreply, socket}
  end

  @impl true
  def handle_event("clear_tableau_view_suggestions", _, socket) do
    socket =
      socket
      |> assign(:tableau_view_suggestions, [])

    {:noreply, socket}
  end

  @impl true
  def handle_event("select_tableau_view", %{"id" => id}, socket) do
    selected_tableau_view =
      socket.assigns.tableau_views
      |> Enum.find(&(&1.id == id))

    {:ok, tableau_image_binary} =
      Tableau.get_view_image_binary(
        selected_tableau_view.id,
        ConnInfo.to_credentials(socket.assigns.data_source.conn_info)
      )

    socket =
      socket
      |> assign(:tableau_view_search_term, selected_tableau_view.full_name)
      |> assign(:tableau_view_suggestions, [])
      |> assign(:tableau_selected_view, selected_tableau_view)
      |> assign(:tableau_image_binary, tableau_image_binary)
      |> assign(:data_loaded, true)

    {:noreply, socket}
  end

  @impl true
  def handle_event("open_query_maker", _params, socket) do
    socket =
      socket
      |> log_event("open_query_maker", %{
        page_name: "report_new"
      })

    socket =
      QueryData.fetch_table_names(%{
        org_id: socket.assigns.org.org_id,
        data_source_id: socket.assigns.data_source.id
      })
      |> case do
        {:ok, tables} ->
          socket
          |> assign(:tables, tables)
          |> push_event("js-exec", %{to: "#query-maker", attr: "data-show-modal"})

        {:error, _} ->
          socket
      end

    {:noreply, socket}
  end

  @impl true
  def handle_event("change_table", params, socket) do
    %{"query_maker_form" => %{"table" => table}} = params

    socket = load_columns(socket, table)

    {:noreply, socket}
  end

  @impl true
  def handle_event("create_query", params, socket) do
    %{
      "query_maker_form" => %{
        "aggregation" => aggregation,
        "value_column" => value_column,
        "date_column" => date_column,
        "value_column_name" => value_column_name,
        "table" => table
      }
    } = params

    value =
      @sql_template_by_maker
      |> EEx.eval_string(
        aggregation: aggregation,
        date_column: date_column,
        value_column: value_column,
        value_column_name: value_column_name,
        table_name: table
      )

    socket =
      socket
      |> log_event("make_query_on_query_maker", %{
        page_name: "report_new"
      })
      |> assign(:sql_template, value)
      |> push_event("js-exec", %{to: "#query-maker", attr: "data-hide-modal"})

    {:noreply, socket}
  end

  @impl true
  def handle_event("validate_query", params, socket) do
    %{"query" => %{"sql_template" => sql_template}} = params

    socket =
      assign(socket, :query_validations, %{
        contains_start: sql_template |> String.contains?("{{start}}"),
        contains_end: sql_template |> String.contains?("{{end}}")
      })

    {:noreply, socket}
  end

  @impl true
  def handle_event("run_query", params, socket) do
    %{"query" => %{"sql_template" => sql_template}} = params

    socket =
      socket
      |> log_event("run_query", %{
        page_name: "report_new"
      })
      |> assign(:sql_template, sql_template)

    socket =
      with {:ok, %{columns: columns, data: data}} <-
             QueryData.query(%{
               org_id: socket.assigns.org.org_id,
               data_source_id: socket.assigns.data_source.id,
               sql_template: sql_template,
               datetime: DateTime.utc_now(),
               timezone: socket.assigns.timezone,
               query_date_length: @query_date_length
             }),
           {:ok, analyzed_data} <-
             QueryData.analyze(data, %{
               columns: columns,
               period: socket.assigns.period,
               window_size: socket.assigns.window_size,
               comparing_period: socket.assigns.comparing_period
             }) do
        preview_data = QueryData.format_data_for_preview(%{columns: columns, data: analyzed_data})

        [_date_column | value_columns] = columns

        parsed_data =
          QueryData.refine_data_based_on_columns(
            %{columns: columns, data: analyzed_data},
            value_columns,
            socket.assigns.window_size
          )

        socket
        |> assign(:query_result, %{columns: columns, data: data})
        |> assign(:query_maker_button_font_size, 14)
        |> assign(:data_loaded, true)
        |> assign(:query_error_message, nil)
        |> assign(:preview, %{columns: columns, data: preview_data})
        |> assign(:query_result_by_columns, parsed_data)
        |> assign(:columns, value_columns)
        |> assign(:selected_columns, value_columns)
        |> add_draw_chart_events(parsed_data, value_columns)
        |> update(
          :report_changeset,
          &ReportParams.changeset(
            &1 |> Params.to_params(),
            ReportParams.init_attrs(%{
              org_id: socket.assigns.org.org_id,
              user_id: socket.assigns.user.id,
              data_target_info: %{
                integration_id: socket.assigns.integration.id
              },
              data_source_info: %{
                data_source_id: socket.assigns.data_source.id,
                sql_template: sql_template,
                period: socket.assigns.period,
                window_size: socket.assigns.window_size,
                comparing_period: socket.assigns.comparing_period,
                columns: value_columns
              }
            })
          )
        )
      else
        {:error, error} ->
          message =
            case error do
              :not_number_type_after_first_column -> "첫 번째 컬럼 이후에는 숫자 타입의 컬럼만 사용할 수 있습니다."
              :first_column_is_not_date_type -> "첫 번째 컬럼은 Date 타입이어야 합니다."
              :sql_not_a_select_query -> "SELECT 문으로 시작되어야 합니다."
              :query_failed -> "쿼리 실행에 실패했습니다."
              {:query_error, message} -> message
              error -> inspect(error)
            end

          socket
          |> log_event("error_query", %{
            page_name: "report_new",
            error_message: message
          })
          |> assign(:query_error_message, "쿼리 실행 중 오류: #{message}")
          |> update(:query_maker_button_font_size, &(&1 + 1))
      end

    {:noreply, socket}
  end

  def handle_event("select_window_size", %{"value" => window_size_str}, socket) do
    window_size = window_size_str |> String.to_integer()

    socket = socket |> assign(:window_size, window_size)

    socket =
      with %{columns: columns, data: data} <- socket.assigns.query_result,
           {:ok, analyzed_data} <-
             QueryData.analyze(data, %{
               columns: columns,
               period: socket.assigns.period,
               window_size: socket.assigns.window_size,
               comparing_period: socket.assigns.comparing_period
             }) do
        [_date_column | value_columns] = columns

        parsed_data =
          QueryData.refine_data_based_on_columns(
            %{columns: columns, data: analyzed_data},
            value_columns,
            socket.assigns.window_size
          )

        report_params = socket.assigns.report_changeset |> Params.to_params()

        report_changeset =
          ReportParams.changeset(
            report_params,
            %{
              data_source_info: %{
                window_size: socket.assigns.window_size
              }
            }
          )

        socket
        |> assign(:query_result_by_columns, parsed_data)
        |> add_draw_chart_events(parsed_data, value_columns)
        |> assign(:report_changeset, report_changeset)
      else
        {:error, error} ->
          socket |> assign(:query_error_message, inspect(error))
      end

    {:noreply, socket}
  end

  @impl true
  def handle_event("validate_report", %{"report" => report_inputs}, socket) do
    report_changeset = validate_report_changeset(socket, report_inputs)

    report_params = report_changeset |> Params.to_params()

    socket =
      socket
      |> assign(:report_changeset, report_changeset)
      |> assign(:report_name, report_inputs["name"])
      |> assign(:hour, report_inputs["hour"])

    socket =
      case socket.assigns.data_source do
        %DataSource{source: source} when source in [:postgres, :mysql, :bigquery, :athena] ->
          socket
          |> assign(:selected_columns, report_params.data_source_info.columns)
          |> add_draw_chart_events(
            socket.assigns.query_result_by_columns,
            report_params.data_source_info.columns
          )

        %DataSource{source: :tableau} ->
          socket
      end

    {:noreply, socket}
  end

  @impl true
  def handle_event(
        "search_slack_channels",
        %{
          "report" => %{
            "data_target_info" => %{
              "channel_search_term" => channel_search_term
            }
          }
        },
        socket
      ) do
    channel_suggestions =
      if String.length(channel_search_term) == 0 do
        socket.assigns.channels
      else
        socket.assigns.channels
        |> Enum.filter(fn {label, _id} -> String.contains?(label, channel_search_term) end)
      end

    socket =
      socket
      |> assign(:channel_suggestions, channel_suggestions)

    {:noreply, socket}
  end

  @impl true
  def handle_event(
        "search_slack_channels",
        %{"value" => channel_search_term},
        socket
      ) do
    channel_suggestions =
      if String.length(channel_search_term) == 0 do
        socket.assigns.channels
      else
        socket.assigns.channels
        |> Enum.filter(fn {label, _id} -> String.contains?(label, channel_search_term) end)
      end

    socket =
      socket
      |> assign(:channel_suggestions, channel_suggestions)

    {:noreply, socket}
  end

  @impl true
  def handle_event("select_slack_channel", %{"channel_id" => channel_id}, socket) do
    channel_name =
      socket.assigns.channels
      |> Enum.find_value(fn
        {channel_name, ^channel_id} -> channel_name
        _ -> nil
      end)

    report_inputs =
      socket.assigns.report_changeset
      |> Params.to_map()
      |> MapHelper.deep_map(fn {k, v} -> {k |> to_string(), v} end)
      |> MapHelper.deep_merge(%{
        "data_target_info" => %{"channel_id" => channel_id}
      })

    report_changeset = validate_report_changeset(socket, report_inputs)

    socket =
      socket
      |> assign(:report_changeset, report_changeset)
      |> assign(:channel_id, channel_id)
      |> assign(:channel_search_term, channel_name)
      |> assign(:channel_suggestions, [])

    {:noreply, socket}
  end

  @impl true
  def handle_event("clear_channel_suggestions", _params, socket) do
    socket =
      socket
      |> assign(:channel_suggestions, [])

    {:noreply, socket}
  end

  @impl true
  def handle_event("save_report", %{"report" => report_inputs}, socket) do
    report_params =
      validate_report_changeset(socket, report_inputs)
      |> Params.to_map()

    socket =
      case socket.assigns.live_action do
        :new -> socket |> create_report(report_params)
        :edit -> socket |> update_report(socket.assigns.report.id, report_params)
      end

    {:noreply, socket}
  end

  @impl true
  def handle_event("send_preview", params, socket) do
    %{"send_preview_form" => %{"channel" => channel_id}} = params

    Task.start(fn ->
      case socket.assigns.data_source do
        %DataSource{source: source} when source in [:postgres, :mysql, :bigquery, :athena] ->
          send_preview_for_rdb(socket, channel_id)

        %DataSource{source: :tableau} ->
          send_preview_for_tableau(socket, channel_id)
      end
      |> then(fn
        :ok ->
          :ok

        {:error, error} ->
          Logger.error(inspect(error))

          {:error, error}
      end)
    end)

    socket =
      socket
      |> log_event("send_test_report", %{
        page_name: "report_new"
      })
      |> put_flash_for(:info, "선택한 쿼리 결과에 대한 슬랙 메시지가 발송되었습니다! 😊", timeout: :timer.seconds(3))
      |> push_event("js-exec", %{to: "#send-preview", attr: "data-hide-modal"})

    {:noreply, socket}
  end

  def handle_event("toggle_show_full_preview_data", _params, socket) do
    socket =
      case socket.assigns.show_full_preview_data do
        false -> log_event(socket, "show_more_query_result", %{page: "report_new"})
        _ -> socket
      end

    socket =
      socket
      |> assign(:show_full_preview_data, !socket.assigns.show_full_preview_data)

    {:noreply, socket}
  end

  @impl true
  def handle_event("refresh_slack_channel_list", _params, socket) do
    if socket.assigns.is_loading_slack_channels do
      {:noreply, socket}
    else
      socket =
        socket
        |> assign(:is_loading_slack_channels, true)
        |> load_slack_channels()
        |> assign(:is_loading_slack_channels, false)

      # TODO: 선택된 채널 초기화

      {:noreply, socket}
    end
  end

  def render_query_preview(assigns) do
    ~H"""
    <%= if @preview do %>
      <header class="flex justify-between mt-6">
        <h2 class="card-title">쿼리 결과 데이터</h2>
      </header>
      <table class="table mt-4">
        <thead>
          <tr class="w-full">
            <%= for header <- @preview.columns do %>
              <th class="text-center py-3 normal-case"><%= header %></th>
            <% end %>
          </tr>
        </thead>
        <tbody>
          <%= for row <- preview_data(@preview.data, @show_full_preview_data) do %>
            <tr class="w-full">
              <%= for value <- row do %>
                <td class="text-center py-2 text-sm bg-base-300"><%= value %></td>
              <% end %>
            </tr>
          <% end %>
        </tbody>
      </table>
      <button
        class="btn btn-outline btn-sm mt-2"
        type="button"
        phx-click="toggle_show_full_preview_data"
      >
        <%= if @show_full_preview_data do %>
          숨기기
        <% else %>
          더보기
        <% end %>
      </button>
    <% end %>
    """
  end

  defp init_common_assigns(socket) do
    # data_source and integration should be assigned before this function is called
    socket
    |> assign(:report_name, "")
    |> assign(
      :data_source_options,
      socket.assigns.data_sources |> Enum.map(fn %{id: id, name: name} -> {name, id} end)
    )
    |> assign(:is_loading_slack_channels, false)
  end

  defp init_assigns_by_data_source(socket) do
    case socket.assigns.data_source do
      %DataSource{source: source} when source in [:postgres, :mysql, :bigquery, :athena] ->
        socket
        |> assign(
          tables: [],
          date_columns: [],
          value_columns: [],
          aggregations: ["SUM", "AVG", "COUNT", "MAX", "MIN"]
        )
        |> assign(:query_maker_button_font_size, 14)
        |> assign(:sample_sql_template, @sample_sql_template)
        |> assign(:sql_template, "")
        |> assign(:query_error_message, nil)
        |> assign(:preview, nil)
        |> assign(:show_full_preview_data, false)
        |> assign(:query_result_by_columns, nil)
        |> assign(:query_validations, %{contains_start: true, contains_end: true})
        |> assign(:period, 28)
        |> assign(:window_size, 1)
        |> assign(:comparing_period, 28)

      %DataSource{source: :tableau} ->
        credentials = ConnInfo.to_credentials(socket.assigns.data_source.conn_info)
        {:ok, views} = Tableau.list_views(credentials)

        # views = [
        #   %Carrier.External.Tableau.View{
        #     id: "606af554-e500-4bac-b0aa-185274434dad",
        #     name: "Obesity",
        #     full_name: "Samples / Regional / Obesity"
        #   },
        #   %Carrier.External.Tableau.View{
        #     id: "ba12d2d7-6fbc-4e5e-b588-c652749d30d8",
        #     name: "College",
        #     full_name: "Samples / Regional / College"
        #   }
        # ]

        socket
        |> assign(:tableau_views, views)
        |> assign(:tableau_view_search_term, "")
        |> assign(:tableau_view_suggestions, [])
        |> assign(:tableau_selected_view, nil)
        |> assign(:tableau_image_binary, nil)
    end
    |> assign(:data_loaded, false)
  end

  defp init_assigns_by_integration(socket) do
    case socket.assigns.integration do
      %DataTarget{service_name: :slack} ->
        {:ok, channels} =
          Slack.list_conversations(socket.assigns.integration.conn_info.info["bot_token"])

        socket
        |> assign(:channels, channels |> Enum.map(fn %{id: id, name: name} -> {name, id} end))
        |> assign(:channel_suggestions, [])
        |> assign(:channel_id, "")
        |> assign(:channel_search_term, "")
        |> assign(:hours, 0..23 |> Enum.map(&{"매일 #{&1}시", &1}))
        |> assign(:hour, "0")
    end
  end

  defp init_changeset(socket) do
    case socket.assigns.data_source do
      %DataSource{source: source} when source in [:postgres, :mysql, :bigquery, :athena] ->
        socket
        |> assign(:report_changeset, ReportParams.changeset(ReportParams.init_attrs()))

      %DataSource{source: :tableau} ->
        socket
        |> assign(:report_changeset, ReportTableau.changeset(ReportTableau.init_attrs()))
    end
  end

  defp load_columns(socket, table_name) do
    QueryData.fetch_columns(%{
      org_id: socket.assigns.org.org_id,
      data_source_id: socket.assigns.data_source.id,
      table_name: table_name
    })
    |> case do
      {:ok, %{date_columns: date_columns, value_columns: value_columns}} ->
        socket
        |> assign(:date_columns, date_columns)
        |> assign(:value_columns, value_columns)

      {:error, _} ->
        socket
    end
  end

  defp load_report(socket) do
    case Reports.fetch_report(socket.assigns.report_id) do
      {:ok, %Report{} = report} ->
        socket
        |> assign(:report, report)

      {:error, error} ->
        Logger.error(inspect(error))

        socket
        |> put_flash_for(:error, "레포트 불러오기에 실패하였습니다.", timeout: :timer.seconds(3))
        |> push_navigate(to: ~p"/app/reports")
    end
  end

  defp create_report(socket, params) do
    case Reports.create_report(params) do
      {:ok, %Report{name: report_name}} ->
        socket
        |> put_flash_for(:info, "\"#{report_name}\" 레포트가 저장되었습니다.", timeout: :timer.seconds(3))
        |> push_navigate(to: ~p"/app/reports")

      {:error, error} ->
        Logger.error(inspect(error))

        socket |> put_flash_for(:error, "레포트 생성에 실패하였습니다.", timeout: :timer.seconds(3))
    end
  rescue
    e ->
      Logger.error(inspect(e))

      socket |> put_flash_for(:error, "레포트 생성에 실패하였습니다.", timeout: :timer.seconds(3))
  end

  defp update_report(socket, report_id, params) do
    case Reports.update_report(report_id, params) do
      {:ok, %Report{name: report_name}} ->
        socket
        |> put_flash_for(:info, "\"#{report_name}\" 레포트가 저장되었습니다.", timeout: :timer.seconds(3))
        |> push_navigate(to: ~p"/app/reports")

      {:error, error} ->
        Logger.error(inspect(error))

        socket |> put_flash_for(:error, "레포트 생성에 실패하였습니다.", timeout: :timer.seconds(3))
    end
  rescue
    e ->
      Logger.error(inspect(e))

      socket |> put_flash_for(:error, "레포트 생성에 실패하였습니다.", timeout: :timer.seconds(3))
  end

  defp add_draw_chart_events(socket, parsed_data, selected_columns) do
    parsed_data
    |> Map.to_list()
    |> Enum.filter(fn {k, _v} -> Enum.member?(selected_columns, k) end)
    |> Enum.reduce(socket, fn {k, v}, acc ->
      push_event(acc, "input_data_#{k}", v)
    end)
  end

  defp load_slack_channels(socket) do
    case Slack.list_conversations(socket.assigns.integration.conn_info.info["bot_token"]) do
      {:ok, channels} ->
        channel_options = channels |> Enum.map(fn %{id: id, name: name} -> {name, id} end)

        socket
        |> assign(:channels, channel_options)
        |> put_flash_for(:info, "슬랙 채널 업데이트 완료", timeout: :timer.seconds(3))

      {:error, _reason} ->
        socket
        |> put_flash_for(:error, "슬랙 채널 업데이트에 실패하였습니다. 다시 시도해주세요.", timeout: :timer.seconds(3))
    end
  end

  defp preview_data(preview, show_all) do
    case show_all do
      true -> preview
      false -> preview |> Enum.take(5)
    end
  end

  defp send_preview_for_rdb(socket, channel_id) do
    data =
      socket.assigns.query_result_by_columns
      |> Map.filter(fn {k, _v} -> k in socket.assigns.selected_columns end)

    with {:ok, %{image_urls: img_urls}} <-
           ImageGenerator.gen_chart_images(%{
             org_id: socket.assigns.org.org_id,
             report_id: "preview",
             data: data
           }),
         {:ok, _} <-
           data
           |> Map.to_list()
           |> Enum.map(fn {k, v} ->
             title = v.meta.label
             image_url = Map.get(img_urls, k)

             blocks = [
               Slack.Block.build_text_block(report_title(socket.assigns.timezone, title)),
               Slack.Block.build_image_block(image_url, title, title)
             ]

             Slack.post_message(
               channel_id,
               blocks,
               socket.assigns.integration.conn_info.info["bot_token"]
             )
           end)
           |> Traversable.traverse() do
      :ok
    end
  end

  defp send_preview_for_tableau(socket, channel_id) do
    with {:ok, url} <-
           ImageGenerator.upload_chart_image(%{
             org_id: socket.assigns.org.org_id,
             report_id: "preview",
             binary: socket.assigns.tableau_image_binary
           }),
         title = socket.assigns.tableau_selected_view.full_name,
         image_url = url,
         blocks = [
           Slack.Block.build_text_block(report_title(socket.assigns.timezone, title)),
           Slack.Block.build_image_block(image_url, title, title)
         ],
         :ok <-
           Slack.post_message(
             channel_id,
             blocks,
             socket.assigns.integration.conn_info.info["bot_token"]
           ) do
      :ok
    end
  end

  defp validate_report_changeset(socket, report_inputs) do
    %{"hour" => hour_str, "data_target_info" => %{"channel_id" => channel_id}} = report_inputs

    trigger_time =
      TimeHelper.from!(hour: hour_str |> String.to_integer())
      |> TimeHelper.to_utc_time(socket.assigns.timezone)

    channel_name =
      socket.assigns.channels
      |> Enum.find_value(fn
        {channel_name, ^channel_id} -> channel_name
        _ -> nil
      end)

    case socket.assigns.data_source do
      %DataSource{source: source} when source in [:postgres, :mysql, :bigquery, :athena] ->
        attrs =
          report_inputs
          |> MapHelper.deep_merge(%{
            "trigger_time" => trigger_time,
            "data_target_info" => %{
              "channel_name" => channel_name,
              "channel_id" => channel_id
            }
          })

        _changeset =
          ReportParams.changeset(attrs)
          |> Params.set_action(:validate)

      %DataSource{source: :tableau} ->
        attrs =
          report_inputs
          |> MapHelper.deep_merge(%{
            "trigger_time" => trigger_time,
            "data_target_info" => %{
              "channel_name" => channel_name,
              "channel_id" => channel_id
            }
          })

        _changeset =
          ReportTableau.changeset(attrs)
          |> Params.set_action(:validate)
    end
  end

  defp is_valid_sql_template(query_validations) do
    query_validations |> Map.values() |> Enum.all?()
  end

  defp report_title(timezone, title) do
    "*📊 #{current_datetime!(timezone) |> DateHelper.safe_format_date()} - #{title}*"
  end
end
