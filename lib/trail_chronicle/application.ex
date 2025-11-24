defmodule TrailChronicle.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      TrailChronicleWeb.Telemetry,
      TrailChronicle.Repo,
      {DNSCluster, query: Application.get_env(:trail_chronicle, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: TrailChronicle.PubSub},
      {Oban, Application.fetch_env!(:trail_chronicle, Oban)},
      # Start the Finch HTTP client for sending emails
      {Finch, name: TrailChronicle.Finch},
      # Start a worker by calling: TrailChronicle.Worker.start_link(arg)
      # {TrailChronicle.Worker, arg},
      # Start to serve requests, typically the last entry
      TrailChronicleWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: TrailChronicle.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    TrailChronicleWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
