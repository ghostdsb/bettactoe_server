defmodule BettactoeServerWeb.BttChannel do
  use Phoenix.Channel
  require Logger

  def join("room:"<>match_data, payload, socket) do
    IO.puts("match data -> #{inspect(match_data)}")
    IO.puts("payload -> #{inspect(payload)}")
    {:ok, socket}
  end

end
