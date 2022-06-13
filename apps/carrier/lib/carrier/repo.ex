defmodule Carrier.Repo do
  use Ecto.Repo,
    otp_app: :carrier,
    adapter: Ecto.Adapters.Postgres
end
