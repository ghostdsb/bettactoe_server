defmodule BettactoeServerWeb.BttChannel do
  use Phoenix.Channel
  require Logger

  def join("room:home", _payload, socket) do
    {:ok, socket}
  end

end
