defmodule CarrierWeb.Components.QueryMaker do
  use Phoenix.LiveComponent
  alias Carrier.Data.QueryData

  def mount(socket) do
    socket =
      QueryData.fetch_table_names(%{
        org_id: socket.assigns.org_id,
        data_source_id: socket.assigns.data_source.id
      })
      |> case do
        {:ok, tables} ->
          socket
          |> assign(:tables, tables)

        {:error, _} ->
          socket
      end

    {:noreply, socket}
  end

  def update(assigns, socket) do
  end

  def render(assigns) do
    ~H"""
      <div class="mt-6">
        <.form
          :let={f}
          for={:query_maker_form}
          autocomplete="off"
          class="space-y-4"
          phx-submit="create_query"
          phx-target="<%= @myself %>"
        >
          <div class="flex items-center gap-x-2">
            <%= label(f, :table, "테이블", class: "label w-20 text-gray-500 text-sm") %>
            <%= select(f, :table, @tables,
              class: "select select-bordered w-60",
              prompt: [key: "테이블을 선택해주세요", disabled: true, selected: true],
              phx_change: "change_table",
              phx_target="<%= @myself %>"
            ) %>
            <%= error_tag(f, :table) %>
          </div>

          <div class="flex items-center gap-x-2">
            <%= label(f, :date_column, "날짜 컬럼", class: "label w-20 text-gray-500 text-sm") %>
            <%= select(f, :date_column, @date_columns,
              class: "select select-bordered w-60",
              selected: @date_columns |> List.first()
            ) %>
            <%= error_tag(f, :date_column) %>
            <%= if length(@date_columns) == 0 do %>
              <div class="text-red-500 text-sm">선택하신 테이블에 날짜 컬럼이 없습니다.</div>
            <% end %>
          </div>

          <div class="flex items-center gap-x-2">
            <%= label(f, :value_column_name, "지표 컬럼", class: "label w-20 text-gray-500 text-sm") %>
            <%= select(f, :value_column, @value_columns,
              class: "select select-bordered w-60",
              selected: @value_columns |> List.first()
            ) %>
            <%= select(f, :aggregation, @aggregations,
              class: "select select-bordered w-60",
              selected: @aggregations |> List.first()
            ) %>
            <%= text_input(f, :value_column_name,
              placeholder: "보여줄 컬럼 이름",
              class: "input input-bordered w-60",
              value: input_value(f, :value_column_name)
            ) %>
            <%= error_tag(f, :value_column) %>
          </div>
          <div class="mt-12">
            <button type="submit" class="w-full btn btn-primary">
              쿼리 생성
            </button>
          </div>
        </.form>
      </div>
    """
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
        pane_name: "report_new"
      })
      |> assign(:sql_template, value)
      |> push_event("js-exec", %{to: "#query-maker", attr: "data-hide-modal"})

    {:noreply, socket}
  end

  @impl true
  def handle_event("change_table", params, socket) do
    %{"query_maker_form" => %{"table" => table}} = params

    socket = load_columns(socket, table)

    {:noreply, socket}
  end

  defp load_columns(socket, table_name) do
    QueryData.fetch_columns(%{
      org_id: socket.assigns.org_id,
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
end
