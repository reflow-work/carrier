defmodule Carrier.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      Carrier.Repo,
      {Phoenix.PubSub, name: Carrier.PubSub},
      {Oban, Application.fetch_env!(:carrier, Oban)},
      Carrier.Vault
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: Carrier.Supervisor)
  end
end
