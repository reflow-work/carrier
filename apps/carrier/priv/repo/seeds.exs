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
            "team_id" => "T03LL747Q49"
          }
        }
      ],
      returning: true
    )

  {_, _} =
    Repo.insert_all(Integration, [
      %{
        org_id: org0.org_id,
        service_name: :slack,
        conn_info_id: conn_info1.id
      }
    ])

  {_, _} =
    Repo.insert_all(DataSource, [
      %{
        org_id: org0.org_id,
        source: :postgres,
        conn_info_id: conn_info0.id
      }
    ])
end)
