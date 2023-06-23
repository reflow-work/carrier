defmodule Carrier.Data.Source.RDB.Demo do
  @behaviour Carrier.Data.Source.RDB

  @impl Carrier.Data.Source.RDB
  def validation_query() do
    "validation_query"
  end

  @impl Carrier.Data.Source.RDB
  def param(n) do
    "$#{n}"
  end

  @impl Carrier.Data.Source.RDB
  def run_query(_credentials, sql, _sql_params \\ [], _opts \\ []) do
    case sql do
      "validation_query" ->
        {:ok, %{columns: ["?column?"], rows: [[1]]}}

      "tableas_query" ->
        {:ok, %{columns: ["table_schema", "table_name"], rows: [["public", "sample_data"]]}}

      "columns_query" ->
        {:ok,
         %{
           columns: ["column_name", "data_type"],
           rows: [
             ["id", "integer"],
             ["order_id", "character varying"],
             ["delivery_date", "date"],
             ["order_date", "date"],
             ["user_id", "character varying"],
             ["user_name", "character varying"],
             ["continent", "character varying"],
             ["country", "character varying"],
             ["region", "character varying"],
             ["city", "character varying"],
             ["segment", "character varying"],
             ["product_id", "character varying"],
             ["product_name", "character varying"],
             ["product_type", "character varying"],
             ["category", "character varying"],
             ["delivery_type", "character varying"],
             ["delivery_level", "character varying"],
             ["delivery_days_actual", "integer"],
             ["delivery_days_reservation", "integer"],
             ["amount", "integer"],
             ["price", "integer"],
             ["revenue", "integer"],
             ["gross_profit", "integer"],
             ["discount", "integer"]
           ]
         }}

      _ ->
        rows =
          [
            Stream.iterate(Date.utc_today(), &(&1 |> Date.add(-1))),
            sample_data() |> Enum.reverse()
          ]
          |> Enum.zip_with(fn [date, [amount_sum, revenue_sum]] ->
            [date, amount_sum, revenue_sum]
          end)
          |> Enum.reverse()

        {:ok, %{columns: ["date", "amount_sum", "revenue_sum"], rows: rows}}
    end
  end

  @impl Carrier.Data.Source.RDB
  def tables_query() do
    "tableas_query"
  end

  @impl Carrier.Data.Source.RDB
  def table_name_field() do
    "table_name"
  end

  @impl Carrier.Data.Source.RDB
  def columns_query() do
    "columns_query"
  end

  @impl Carrier.Data.Source.RDB
  def column_name_field() do
    "column_name"
  end

  @impl Carrier.Data.Source.RDB
  def data_type_field() do
    "data_type"
  end

  @impl Carrier.Data.Source.RDB
  def is_date_type?(type) do
    cond do
      type == "date" -> true
      type |> String.starts_with?("timestamp") -> true
      true -> false
    end
  end

  defp sample_data() do
    [
      [5, 50550],
      [7, 73141],
      [8, 80953],
      [8, 84572],
      [12, 127_600],
      [8, 82036],
      [3, 31510],
      [6, 60660],
      [15, 163_211],
      [9, 96242],
      [12, 121_615],
      [13, 133_183],
      [14, 146_210],
      [17, 184_000],
      [17, 174_207],
      [15, 155_355],
      [16, 169_700],
      [12, 124_262],
      [18, 183_273],
      [20, 206_552],
      [21, 230_061],
      [18, 191_018],
      [19, 190_296],
      [13, 130_830],
      [20, 207_405],
      [25, 252_924],
      [37, 406_630],
      [24, 244_736],
      [26, 271_249],
      [28, 294_114],
      [17, 183_714],
      [15, 153_949],
      [32, 333_170],
      [29, 312_515],
      [30, 320_933],
      [51, 551_607],
      [45, 484_296],
      [56, 568_295],
      [50, 507_694],
      [53, 555_625],
      [57, 598_995],
      [55, 596_495],
      [59, 609_665],
      [62, 677_674],
      [63, 691_382],
      [65, 667_642],
      [60, 628_000],
      [63, 633_073],
      [69, 694_553],
      [72, 783_890],
      [73, 731_796],
      [71, 744_488],
      [65, 697_309],
      [73, 730_475],
      [87, 871_790],
      [90, 969_583],
      [93, 951_796],
      [91, 951_479],
      [95, 1_005_533],
      [96, 1_048_813],
      [105, 1_124_750],
      [115, 1_232_745],
      [124, 1_346_845],
      [137, 1_417_572],
      [151, 1_607_787],
      [177, 1_902_143]
    ]
  end
end
