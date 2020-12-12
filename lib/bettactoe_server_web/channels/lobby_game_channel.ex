defmodule BettactoeServerWeb.LobbyGameChannel do
  use Phoenix.Channel
  alias BettactoeServerWeb.Presence

  def join("lobby:btt", params, socket) do
    Process.send_after(self(), {"after_join", params}, 500)
    {:ok, socket}
  end

  def handle_info({"after_join", _params}, socket) do
    Process.send_after(self(), "game_joined", 100)
    {:noreply, socket}
  end

  def handle_info("game_joined", socket) do
    {:ok, _} = Presence.track(socket, socket.assigns.player_id, %{
      online_at: inspect(System.system_time(:second))
    })

    push(socket, "presence_game_state", Presence.list(socket))
    {:noreply, socket}
  end

end
