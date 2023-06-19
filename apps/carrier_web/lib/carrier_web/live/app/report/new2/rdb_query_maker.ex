defmodule CarrierWeb.App.ReportLive.New2.RDBQueryMaker do
  use CarrierWeb, :live_component
  use Carrier.Data
  alias Carrier.Data.QueryData

  @sql_template_source """
  SELECT
    DATE(<%= date_column %>),
    <%= aggregation %>(<%= value_column %>) AS "<%= if value_column_name != "", do: value_column_name, else: value_column %>"
  FROM <%= table_name %>
    WHERE DATE(<%= date_column %>) >= {{start}}
      AND DATE(<%= date_column %>) < {{end}}
    GROUP BY 1
  """

  @impl true
  def mount(socket) do
    socket =
      socket
      |> assign(:data_source, nil)
      |> assign(:table_names, [])
      |> assign(:date_columns, [])
      |> assign(:value_columns, [])
      |> assign(:aggregations, ["SUM", "AVG", "COUNT", "MAX", "MIN"])

    {:ok, socket}
  end

  @impl true
  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> load_table_names()

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.simple_form
        for={%{}}
        phx-target={@myself}
        phx-change="form_changed"
        phx-submit="form_submitted"
      >
        <.input
          type="select"
          input_class="w-60"
          name="table"
          label="테이블"
          label_align={:left}
          options={@table_names}
          prompt="테이블을 선택해주세요"
          value=""
        />
        <.input
          type="select"
          input_class="w-60"
          name="date_column"
          label="날짜 컬럼"
          label_align={:left}
          options={@date_columns}
          value={@date_columns |> List.first()}
        />
        <div class="flex items-center gap-x-2">
          <.input
            type="select"
            input_class="w-60"
            name="value_column"
            label="지표 컬럼"
            label_align={:left}
            options={@value_columns}
            value={@value_columns |> List.first()}
          />
          <.input
            type="select"
            input_class="w-60"
            name="aggregation"
            options={@aggregations}
            value={@aggregations |> List.first()}
          />
          <.input
            type="text"
            input_class="w-60"
            name="value_column_name"
            value=""
            placeholder="보여줄 컬럼 이름"
          />
        </div>
        <:actions>
          <.button>쿼리 생성</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def handle_event("form_changed", %{"table" => table_name}, socket) do
    socket =
      socket
      |> load_columns(table_name)

    {:noreply, socket}
  end

  @impl true
  def handle_event(
        "form_submitted",
        %{
          "table" => table_name,
          "date_column" => date_column,
          "value_column" => value_column,
          "aggregation" => aggregation,
          "value_column_name" => value_column_name
        },
        socket
      ) do
    sql_template =
      @sql_template_source
      |> EEx.eval_string(
        aggregation: aggregation,
        date_column: date_column,
        value_column: value_column,
        value_column_name: value_column_name,
        table_name: table_name
      )

    socket.assigns.onsuccess.(sql_template)

    {:noreply, socket}
  end

  defp load_table_names(socket) do
    case QueryData.fetch_table_names(%{
           org_id: socket.assigns.data_source.org_id,
           data_source_id: socket.assigns.data_source.id
         }) do
      {:ok, table_names} ->
        socket
        |> assign(:table_names, table_names)

      {:error, _} ->
        socket
    end
  end

  defp load_columns(socket, table_name) do
    case QueryData.fetch_columns(%{
           org_id: socket.assigns.data_source.org_id,
           data_source_id: socket.assigns.data_source.id,
           table_name: table_name
         }) do
      {:ok, %{date_columns: date_columns, value_columns: value_columns}} ->
        socket
        |> assign(:date_columns, date_columns)
        |> assign(:value_columns, value_columns)

      {:error, _} ->
        socket
    end
  end
end
