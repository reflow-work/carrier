defmodule Carrier.Repo do
  use Ecto.Repo,
    otp_app: :carrier,
    adapter: Ecto.Adapters.Postgres

  use Doumi.RepoHelper
end
