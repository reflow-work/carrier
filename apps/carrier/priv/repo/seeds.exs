# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Carrier.Repo.insert!(%Carrier.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias Carrier.Accounts.{Org, User}
alias Carrier.Secrets.{ConnInfo, Integration, DataSource}
alias Carrier.Reports.Report
alias Carrier.Repo

Repo.transaction(fn ->
  {_, [org0]} = Repo.insert_all(Org, [%{name: "org0"}], returning: true)

  {_, _} =
    Repo.insert_all(User, [
      %{org_id: org0.org_id, email: "nallwhy@gmail.com"},
      %{org_id: org0.org_id, email: "wonny727@gmail.com"},
      %{org_id: org0.org_id, email: "bonghyun.d.kim@gmail.com"},
      %{org_id: org0.org_id, email: "ftsgsd@gmail.com"}
    ])

  {_, [conn_info0, conn_info1]} =
    Repo.insert_all(
      ConnInfo,
      [
        %{
          org_id: org0.org_id,
          name: "test DB",
          source: :postgres,
          info: %{
            "hostname" => "test-db.cdw6skjbo8fk.ap-northeast-2.rds.amazonaws.com",
            "port" => 5432,
            "username" => "postgres",
            "password" => "JJJxcv7MUzaFct9R6vEB",
            "database" => "test_db"
          }
        },
        %{
          org_id: org0.org_id,
          name: "slack",
          source: :slack,
          info: %{
            "team_name" => "dongrami",
            "team_id" => "T03LL747Q49",
            "bot_token" => "xoxb-3700242262145-3896134834753-QZ1WpkILGCgWy7bctc47CoLz"
          }
        }
      ],
      returning: true
    )

  {_, [integration0]} =
    Repo.insert_all(
      Integration,
      [
        %{
          org_id: org0.org_id,
          service_name: :slack,
          conn_info_id: conn_info1.id
        }
      ],
      returning: true
    )

  {_, [data_source0]} =
    Repo.insert_all(
      DataSource,
      [
        %{
          org_id: org0.org_id,
          name: "main db",
          source: :postgres,
          conn_info_id: conn_info0.id
        }
      ],
      returning: true
    )

  {_, _} =
    Repo.insert_all(Report, [
      %{
        org_id: org0.org_id,
        name: "json is babo",
        trigger_time: ~T[01:00:00],
        integration_info: %Report.IntegrationInfo{
          integration_id: integration0.id,
          channel_id: "C03NXJZ1SPJ"
        },
        data_source_info: %Report.DataSourceInfo{
          data_source_id: data_source0.id,
          sql_template: """
          SELECT DATE(order_date) as date, SUM(amount) AS total_amount, SUM(revenue) AS total_revenue
            FROM sample_data_simple
            WHERE DATE(order_date) >= {{start}} AND DATE(order_date) < {{end}}
            GROUP BY order_date
            ORDER BY order_date
          """,
          timezone: "Asia/Seoul",
          period: 28,
          window_size: 7,
          comparing_period: 7,
          columns: ["total_amount", "total_revenue"]
        }
      }
    ])
end)
