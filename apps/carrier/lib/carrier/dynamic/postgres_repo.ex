defmodule Carrier.Dynamic.PostgresRepo do
  use Ecto.Repo,
    otp_app: :carrier,
    adapter: Ecto.Adapters.Postgres

  def with_dynamic_repo(credentials, callback) do
    start_opts = [name: nil, pool_size: 1] ++ credentials
    {:ok, repo} = __MODULE__.start_link(start_opts)

    try do
      callback.(repo)
    after
      Supervisor.stop(repo)
    end
  end
end
