defmodule Carrier.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      Carrier.Repo,
      # Start the PubSub system
      {Phoenix.PubSub, name: Carrier.PubSub}
      # Start a worker by calling: Carrier.Worker.start_link(arg)
      # {Carrier.Worker, arg}
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: Carrier.Supervisor)
  end
end
