defmodule AiAssistant.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      AiAssistantWeb.Telemetry,
      # Start the Ecto repository
      AiAssistant.Repo,
      # Start the PubSub system
      {Phoenix.PubSub, name: AiAssistant.PubSub},
      # Start Finch
      {Finch, name: AiAssistant.Finch},
      # Start the Endpoint (http/https)
      AiAssistantWeb.Endpoint
      # Start a worker by calling: AiAssistant.Worker.start_link(arg)
      # {AiAssistant.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: AiAssistant.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    AiAssistantWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
