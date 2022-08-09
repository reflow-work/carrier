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

alias Carrier.Accounts.Org
alias Carrier.Secrets.ConnInfo
alias Carrier.Repo

Repo.transaction(fn ->
  {_, [org0]} = Repo.insert_all(Org, [%{name: "org0"}], returning: true)

  Repo.insert_all(ConnInfo, [
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
    }
  ])
end)
