defmodule Carrier.Dynamic.PostgresRepo do
  use Ecto.Repo,
    otp_app: :carrier,
    adapter: Ecto.Adapters.Postgres

  @default_opts [
    name: nil,
    pool_size: 1,
    max_restarts: 1,
    queue_interval: :timer.seconds(2),
    timeout: :timer.minutes(2)
  ]
  def with_dynamic_repo(credentials, opts \\ [], callback) when is_function(callback, 0) do
    default_dynamic_repo = get_dynamic_repo()

    start_opts =
      @default_opts
      |> Keyword.merge(opts)
      |> Keyword.merge(Keyword.new(credentials))

    {:ok, repo} = __MODULE__.start_link(start_opts)

    try do
      put_dynamic_repo(repo)
      callback.()
    after
      put_dynamic_repo(default_dynamic_repo)
      Supervisor.stop(repo)
    end
  end
end
