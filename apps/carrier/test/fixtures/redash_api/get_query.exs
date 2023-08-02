%{
  "api_key" => "uWcSn7XmWhrBc0r7z7KdDoewSBi3esHGjHEIJYx3",
  "can_edit" => true,
  "created_at" => "2023-07-28T02:35:42.668Z",
  "data_source_id" => 1,
  "description" => nil,
  "id" => 1,
  "is_archived" => false,
  "is_draft" => false,
  "is_favorite" => false,
  "is_safe" => false,
  "last_modified_by" => %{
    "active_at" => "2023-08-02T11:01:41Z",
    "auth_type" => "password",
    "created_at" => "2023-07-27T10:37:19.041Z",
    "disabled_at" => nil,
    "email" => "nallwhy@gmail.com",
    "groups" => [1, 2],
    "id" => 1,
    "is_disabled" => false,
    "is_email_verified" => true,
    "is_invitation_pending" => false,
    "name" => "json",
    "profile_image_url" => "https://www.gravatar.com/avatar/60666dc6d6dcacd03fe979d24fe0a713?s=40&d=identicon",
    "updated_at" => "2023-08-02T11:01:59.508Z"
  },
  "latest_query_data_id" => nil,
  "name" => "New Query",
  "options" => %{
    "apply_auto_limit" => true,
    "parameters" => [
      %{
        "global" => false,
        "locals" => [],
        "name" => "date",
        "title" => "date",
        "type" => "date",
        "value" => "d_now"
      },
      %{"locals" => [], "name" => "text", "title" => "Text", "type" => "text", "value" => "text"},
      %{
        "locals" => [],
        "name" => "testtest",
        "title" => "Testtest",
        "type" => "datetime-local",
        "value" => "d_now"
      },
      %{
        "locals" => [],
        "name" => "tests",
        "title" => "Tests",
        "type" => "datetime-with-seconds",
        "value" => "d_now"
      },
      %{
        "locals" => [],
        "name" => "daterange",
        "title" => "Daterange",
        "type" => "date-range",
        "value" => "d_this_week"
      },
      %{
        "locals" => [],
        "name" => "dtr",
        "title" => "Dtr",
        "type" => "datetime-range",
        "value" => "d_last_12_months"
      },
      %{
        "locals" => [],
        "name" => "dtrs",
        "title" => "Dtrs",
        "type" => "datetime-range-with-seconds",
        "value" => "d_last_7_days"
      }
    ]
  },
  "query" => "SELECT\n  order_date as date,\n  SUM(amount) AS total_amount,\n  SUM(revenue) AS total_revenue,\n  '{{ date }}',\n  '{{ text }}',\n  '{{ testtest }}',\n  '{{ tests }}',\n  '{{ daterange.start }}',\n  '{{ daterange.end }}',\n  '{{ dtr.start }}',\n  '{{ dtr.end }}',\n  '{{ dtrs.start }}',\n  '{{ dtrs.end }}'\nFROM\n  sample_data\nWHERE\n  order_date >= '2023-01-01'\n  AND order_date < '2023-07-28'\nGROUP BY\n  order_date\nORDER BY\n  order_date;",
  "query_hash" => "facd966fe63663ee9382f79ef3db710c",
  "schedule" => %{"day_of_week" => nil, "interval" => 86400, "time" => "15:15", "until" => nil},
  "tags" => [],
  "updated_at" => "2023-08-02T11:02:32.903Z",
  "user" => %{
    "active_at" => "2023-08-02T11:01:41Z",
    "auth_type" => "password",
    "created_at" => "2023-07-27T10:37:19.041Z",
    "disabled_at" => nil,
    "email" => "nallwhy@gmail.com",
    "groups" => [1, 2],
    "id" => 1,
    "is_disabled" => false,
    "is_email_verified" => true,
    "is_invitation_pending" => false,
    "name" => "json",
    "profile_image_url" => "https://www.gravatar.com/avatar/60666dc6d6dcacd03fe979d24fe0a713?s=40&d=identicon",
    "updated_at" => "2023-08-02T11:01:59.508Z"
  },
  "version" => 1,
  "visualizations" => [
    %{
      "created_at" => "2023-07-28T02:35:42.668Z",
      "description" => "",
      "id" => 1,
      "name" => "Table",
      "options" => %{},
      "type" => "TABLE",
      "updated_at" => "2023-07-28T02:35:42.668Z"
    },
    %{
      "created_at" => "2023-07-28T02:49:14.908Z",
      "description" => "",
      "id" => 2,
      "name" => "Chartdddd",
      "options" => %{
        "alignYAxesAtZero" => false,
        "coefficient" => 1,
        "columnMapping" => %{"date" => "x", "total_amount" => "y"},
        "dateTimeFormat" => "DD/MM/YY HH:mm",
        "direction" => %{"type" => "counterclockwise"},
        "error_y" => %{"type" => "data", "visible" => true},
        "globalSeriesType" => "line",
        "legend" => %{"enabled" => true, "placement" => "auto", "traceorder" => "normal"},
        "missingValuesAsZero" => true,
        "numberFormat" => "0,0[.]00000",
        "percentFormat" => "0[.]00%",
        "series" => %{"error_y" => %{"type" => "data", "visible" => true}, "stacking" => nil},
        "seriesOptions" => %{},
        "showDataLabels" => false,
        "sizemode" => "diameter",
        "sortX" => true,
        "swappedAxes" => false,
        "textFormat" => "",
        "valuesOptions" => %{},
        "xAxis" => %{"labels" => %{...}, ...},
        "yAxis" => [...]
      },
      "type" => "CHART",
      "updated_at" => "2023-07-28T09:34:16.302Z"
    }
  ]
}
