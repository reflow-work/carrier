ExUnit.start()
Application.ensure_all_started(:bypass)
Ecto.Adapters.SQL.Sandbox.mode(Carrier.Repo, :manual)
Ecto.Adapters.SQL.Sandbox.mode(Carrier.TenantRepo, :manual)
