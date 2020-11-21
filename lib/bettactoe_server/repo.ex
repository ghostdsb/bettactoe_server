defmodule BettactoeServer.Repo do
  use Ecto.Repo,
    otp_app: :bettactoe_server,
    adapter: Ecto.Adapters.Postgres
end
