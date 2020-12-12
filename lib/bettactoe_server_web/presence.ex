defmodule BettactoeServerWeb.Presence do
  use Phoenix.Presence,
    otp_app: :my_app,
    pubsub_server: BettactoeServer.PubSub
end
