# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :bettactoe_server,
  ecto_repos: [BettactoeServer.Repo]

# Configures the endpoint
config :bettactoe_server, BettactoeServerWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "noEIG1a7iKfhjZhBxDns9Hrm8jcFThk8BlE1ooVWZn7kY9MARsDClN09YRwtI/T/",
  render_errors: [view: BettactoeServerWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: BettactoeServer.PubSub,
  live_view: [signing_salt: "Sj92GJNu"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
