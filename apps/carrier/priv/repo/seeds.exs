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

use Carrier.{Accounts, Integrations, Reports, Setting, Billing, Roles}
alias Carrier.Repo

now = DateTime.utc_now()

Repo.transaction(fn ->
  {_, [org0, org1]} =
    Repo.insert_all(
      Org,
      [
        %{name: "org0", industry: "IT 서비스", employee_count: "1~4명"},
        %{name: "org1", industry: "IT 서비스", employee_count: "1~4명"}
      ],
      returning: true
    )

  {_, [admin_role, _]} =
    Repo.insert_all(
      Role,
      [
        %{
          name: "Admin",
          permissions: [
            "member.manage",
            "billing.payment.manage"
          ]
        },
        %{
          name: "Member",
          permissions: []
        }
      ],
      returning: true
    )

  {_, _} =
    Repo.insert_all(User, [
      %{org_id: org0.org_id, email: "nallwhy@gmail.com", role_id: admin_role.id},
      %{org_id: org1.org_id, email: "wonny727@gmail.com", role_id: admin_role.id}
    ])

  {_, [conn_info0, conn_info1, conn_info2, conn_info3]} =
    Repo.insert_all(
      ConnInfo,
      [
        %{
          org_id: org0.org_id,
          name: "test DB",
          source: :postgres,
          info: %{
            "hostname" => "db.cdigyzxhugungdxntpwg.supabase.co",
            "port" => 5432,
            "username" => "postgres",
            "password" => "2IIx7Xk5KoiB",
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
        },
        %{
          org_id: org1.org_id,
          name: "test DB",
          source: :postgres,
          info: %{
            "hostname" => "db.cdigyzxhugungdxntpwg.supabase.co",
            "port" => 5432,
            "username" => "postgres",
            "password" => "2IIx7Xk5KoiB",
            "database" => "test_db"
          }
        },
        %{
          org_id: org1.org_id,
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

  {_, [data_target0, data_target1]} =
    Repo.insert_all(
      DataTarget,
      [
        %{
          org_id: org0.org_id,
          service_name: :slack,
          conn_info_id: conn_info1.id
        },
        %{
          org_id: org1.org_id,
          service_name: :slack,
          conn_info_id: conn_info3.id
        }
      ],
      returning: true
    )

  {_, [data_source0, data_source1]} =
    Repo.insert_all(
      DataSource,
      [
        %{
          org_id: org0.org_id,
          name: "main db",
          source: :postgres,
          conn_info_id: conn_info0.id
        },
        %{
          org_id: org1.org_id,
          name: "main db",
          source: :postgres,
          conn_info_id: conn_info2.id
        }
      ],
      returning: true
    )

  {_, [report_info0, report_info1]} =
    Repo.insert_all(
      ReportInfo,
      [
        %{org_id: org0.org_id},
        %{org_id: org1.org_id}
      ],
      returning: true
    )

  {_, [report0, report1]} =
    Repo.insert_all(
      Report,
      [
        %{
          org_id: org0.org_id,
          report_info_id: report_info0.id,
          name: "json is babo",
          trigger_time: ~T[01:00:00],
          timezone: "Asia/Seoul",
          data_target_info: %DataTargetInfo{
            data_target_id: data_target0.id,
            channel_id: "C03U2QWU7F1",
            channel_name: "message_tests"
          },
          data_source_info: %{
            data_source_id: data_source0.id,
            source: "postgres",
            sql_template: """
            SELECT order_date as date, SUM(amount) AS total_amount, SUM(revenue) AS total_revenue
              FROM sample_data
              WHERE order_date >= {{start}} AND order_date < {{end}}
              GROUP BY order_date
              ORDER BY order_date
            """,
            timezone: "Asia/Seoul",
            period: 28,
            window_size: 7,
            comparing_period: 28,
            columns: ["total_amount", "total_revenue"]
          }
        },
        %{
          org_id: org1.org_id,
          report_info_id: report_info1.id,
          name: "wonny is babo",
          trigger_time: ~T[01:00:00],
          timezone: "Asia/Seoul",
          data_target_info: %DataTargetInfo{
            data_target_id: data_target1.id,
            channel_id: "C03U2QWU7F1",
            channel_name: "message_tests"
          },
          data_source_info: %{
            data_source_id: data_source1.id,
            source: "postgres",
            sql_template: """
            SELECT order_date as date, SUM(amount) AS total_amount, SUM(revenue) AS total_revenue
              FROM sample_data
              WHERE order_date >= {{start}} AND order_date < {{end}}
              GROUP BY order_date
              ORDER BY order_date
            """,
            timezone: "Asia/Seoul",
            period: 28,
            window_size: 7,
            comparing_period: 28,
            columns: ["total_amount", "total_revenue"]
          }
        }
      ],
      returning: true
    )

  {:ok, _} = Reports.create_job_from_report(report0, now, %{repo: Repo})
  {:ok, _} = Reports.create_job_from_report(report1, now, %{repo: Repo})

  {3, _} =
    Repo.insert_all(FeatureFlag, [
      %{key: "test", description: "for testing", value: false},
      %{key: "data_source_athena", description: "athena", value: true},
      %{key: "data_source_tableau", description: "tableau", value: true}
    ])

  {1, _} =
    Repo.insert_all(Property, [%{key: "max_data_source_count", type: :integer, value: 100}])

  {_, [_trial_plan, _basic_monthly_plan, _pro_monthly_plan | _]} =
    Repo.insert_all(
      Plan,
      [
        %{
          billing_cycle: :none,
          name: "Trial",
          type: :trial,
          price: 0,
          currency: :KRW,
          description: ["모든 기능 사용 가능"],
          subscribable: false
        },
        %{
          billing_cycle: :monthly,
          name: "Basic",
          type: :basic,
          price: 48000,
          currency: :KRW,
          description: ["SQL 쿼리를 사용하는 리포트 사용 가능", "리포트 최대 50개"],
          subscribable: true
        },
        %{
          billing_cycle: :monthly,
          name: "Pro",
          type: :pro,
          price: 150_000,
          currency: :KRW,
          description: ["SQL 쿼리를 사용하는 리포트 사용 가능", "태블로 연동 리포트 사용 가능", "리포트 무제한"],
          subscribable: true
        },
        %{
          billing_cycle: :yearly,
          name: "Basic",
          type: :basic,
          original_price: 576_000,
          price: 480_000,
          currency: :KRW,
          description: ["SQL 쿼리를 사용하는 리포트 사용 가능", "리포트 최대 50개"],
          subscribable: true
        },
        %{
          billing_cycle: :yearly,
          name: "Pro",
          type: :pro,
          original_price: 1_800_000,
          price: 1_500_000,
          currency: :KRW,
          description: ["SQL 쿼리를 사용하는 리포트 사용 가능", "태블로 연동 리포트 사용 가능", "리포트 무제한"],
          subscribable: true
        }
      ],
      returning: true
    )

  # {_, _} =
  #   Repo.insert_all(Subscription, [
  #     %{
  #       org_id: org0.org_id,
  #       plan_id: pro_monthly_plan.id,
  #       start_on: now,
  #       end_on: Plan.calc_end_on(pro_monthly_plan, now, 0),
  #       status: :active,
  #       activated_at: now
  #     }
  #   ])
end)
