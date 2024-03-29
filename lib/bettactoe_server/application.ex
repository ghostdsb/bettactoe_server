defmodule BettactoeServer.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      # BettactoeServer.Repo,
      # Start the Telemetry supervisor
      BettactoeServerWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: BettactoeServer.PubSub},
      # Start the Endpoint (http/https)
      BettactoeServerWeb.Presence,
      BettactoeServerWeb.Endpoint,
      Garuda.Matchmaker.MatchmakerSupervisor,
      {Registry, keys: :unique, name: BettactoeServerWeb.GameRegistry},
      {DynamicSupervisor, strategy: :one_for_one, name: BettactoeServerWeb.BttSupervisor},
      # Start a worker by calling: BettactoeServer.Worker.start_link(arg)
      # {BettactoeServer.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: BettactoeServer.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    BettactoeServerWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
