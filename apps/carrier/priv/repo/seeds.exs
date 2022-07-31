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
      name: "conn0",
      source: :postgres,
      info: %{
        "hostname" => "localhost",
        "port" => 48141,
        "username" => "customer",
        "password" => "password",
        "database" => "customer_db"
      }
    }
  ])
end)
