defmodule KoveRiders.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      KoveRidersWeb.Telemetry,
      KoveRiders.Repo,
      {DNSCluster, query: Application.get_env(:kove_riders, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: KoveRiders.PubSub},
      {Task.Supervisor, name: KoveRiders.TaskSupervisor},
      # Start to serve requests, typically the last entry
      KoveRidersWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: KoveRiders.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    KoveRidersWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
