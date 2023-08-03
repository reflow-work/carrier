%{
  "api_key" => "c9XyGunZiDxlvDUQXQuRXnOFyletEcDe9GOZtoyM",
  "can_edit" => true,
  "created_at" => "2023-07-28T02:49:56.864Z",
  "dashboard_filters_enabled" => false,
  "id" => 1,
  "is_archived" => false,
  "is_draft" => false,
  "is_favorite" => false,
  "layout" => [],
  "name" => "내 퍼킹한 대시보드",
  "options" => %{},
  "public_url" =>
    "http://localhost:5001/public/dashboards/c9XyGunZiDxlvDUQXQuRXnOFyletEcDe9GOZtoyM?org_slug=default",
  "slug" => "-",
  "tags" => [],
  "updated_at" => "2023-08-02T01:48:19.696Z",
  "user" => %{
    "email" => "nallwhy@gmail.com",
    "id" => 1,
    "name" => "json",
    "profile_image_url" =>
      "https://www.gravatar.com/avatar/60666dc6d6dcacd03fe979d24fe0a713?s=40&d=identicon"
  },
  "user_id" => 1,
  "version" => 4,
  "widgets" => [
    %{
      "created_at" => "2023-07-28T02:50:15.410Z",
      "dashboard_id" => 1,
      "id" => 1,
      "options" => %{
        "isHidden" => false,
        "parameterMappings" => %{},
        "position" => %{
          "autoHeight" => false,
          "col" => 0,
          "maxSizeX" => 6,
          "maxSizeY" => 1000,
          "minSizeX" => 1,
          "minSizeY" => 5,
          "row" => 0,
          "sizeX" => 3,
          "sizeY" => 7
        }
      },
      "text" => "",
      "updated_at" => "2023-07-28T02:51:13.451Z",
      "visualization" => %{
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
          ...
        },
        "query" => %{
          "api_key" => "uWcSn7XmWhrBc0r7z7KdDoewSBi3esHGjHEIJYx3",
          "created_at" => "2023-07-28T02:35:42.668Z",
          "data_source_id" => 1,
          "description" => nil,
          "id" => 1,
          "is_archived" => false,
          "is_draft" => false,
          "is_safe" => true,
          "last_modified_by" => %{
            "active_at" => "2023-08-02T03:33:46Z",
            "auth_type" => "password",
            "created_at" => "2023-07-27T10:37:19.041Z",
            "disabled_at" => nil,
            "email" => "nallwhy@gmail.com",
            "groups" => [1, 2],
            "id" => 1,
            "is_disabled" => false,
            ...
          },
          "latest_query_data_id" => 2,
          "name" => "New Query",
          "options" => %{"apply_auto_limit" => true, "parameters" => []},
          "query" =>
            "SELECT\n  order_date as date,\n  SUM(amount) AS total_amount,\n  SUM(revenue) AS total_revenue\nFROM\n  sample_data\nWHERE\n  order_date >= '2023-01-01'\n  AND order_date < '2023-07-28'\nGROUP BY\n  order_date\nORDER BY\n  order_date;",
          "query_hash" => "f26758ac6d78d52bee88763b57f83c36",
          "schedule" => nil,
          "tags" => [],
          "updated_at" => "2023-07-28T02:50:46.322Z",
          ...
        },
        "type" => "CHART",
        "updated_at" => "2023-07-28T09:34:16.302Z"
      },
      "width" => 1
    },
    %{
      "created_at" => "2023-07-28T11:34:49.253Z",
      "dashboard_id" => 1,
      "id" => 2,
      "options" => %{
        "isHidden" => false,
        "position" => %{
          "autoHeight" => false,
          "col" => 3,
          "maxSizeX" => 6,
          "maxSizeY" => 1000,
          "minSizeX" => 1,
          "minSizeY" => 1,
          "row" => 0,
          "sizeX" => 3,
          "sizeY" => 27
        }
      },
      "text" => "wwwww",
      "updated_at" => "2023-07-28T11:35:00.743Z",
      "width" => 1
    }
  ]
}
