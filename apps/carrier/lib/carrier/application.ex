defmodule Carrier.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      Carrier.Core.Cache.Local,
      Carrier.Repo,
      {Phoenix.PubSub, name: Carrier.PubSub},
      {Oban, Application.fetch_env!(:carrier, Oban)},
      Carrier.Vault,
      {Finch, name: Carrier.Finch, pools: %{default: [size: 100]}},
      {DynamicSupervisor, strategy: :one_for_one, name: Carrier.GothSupervisor},
      {Task.Supervisor, name: Carrier.TaskSupervisor},
      Carrier.PythonPool
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: Carrier.Supervisor)
  end
end
