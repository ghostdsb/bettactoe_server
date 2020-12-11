defmodule BettactoeServerWeb.BttChannel do
  use Phoenix.Channel
  alias BettactoeServer.BttRoom
  alias BettactoeServerWeb.Utils.Records

  intercept [ "start_game" ]

  def join("btt:" <> match_id, params, socket) do
    Process.send_after(self(), {"after_join", match_id, params["name"]}, 500)
    {:ok, socket}
  end

  def handle_in("bet", payload, socket) do
    IO.puts("bet payload: #{inspect(payload)}")
    bet_data = payload["betdata"]
    gs =
      Records.via_tuple(socket.assigns.match_id)
    |> BttRoom.bet(bet_data["playerId"], bet_data["bet"])

    cond do
      gs.turn === nil ->
        IO.puts("waiting for other player")
      true ->
        broadcast(socket, "bet_res", %{
        "board" => gs.board,
        "turn" => %{id: gs.turn},
        "p1" => %{id: gs.player_1.id, bet: gs.player_1.bet, balance: gs.player_1.balance},
        "p2" => %{id: gs.player_2.id, bet: gs.player_2.bet, balance: gs.player_2.balance}})
    end
    {:noreply, socket}
  end

  def handle_in("move", payload, socket) do
    move_data = payload["movedata"]
    gs = Records.via_tuple(socket.assigns.match_id)
    |> BttRoom.move(move_data["pos"])
    cond do
      gs.gameover.state === true ->
        broadcast(socket, "game_res", %{ board: gs.board, winner: gs.gameover.winner, pattern: gs.gameover.pattern})
      true ->
        broadcast(socket, "move_res", %{
          "board" => gs.board,
          "p1" => %{id: gs.player_1.id, bet: gs.player_1.bet, balance: gs.player_1.balance},
          "p2" => %{id: gs.player_2.id, bet: gs.player_2.bet, balance: gs.player_2.balance}
          })
    end
    {:noreply, socket}
  end

  def handle_out("start_game", payload, socket) do
    push(socket, "start_game_event", payload)
    {:noreply, socket}
  end

  def handle_info({"after_join", match_id, name}, socket) do
    socket = assign(socket, :match_id, match_id)

    match_id
    |> create_btt_room()
    |> add_player_to_btt_room(match_id, name, socket)

    {:noreply, socket}
  end


  defp create_btt_room(match_id) do
    DynamicSupervisor.start_child(
      BettactoeServerWeb.BttSupervisor,
      {BttRoom, name: Records.via_tuple(match_id), info: match_id}
    )
  end

  defp add_player_to_btt_room({:ok, _child}, match_id, name, socket) do
    match_id |> join_player(socket.assigns.player_id, name)
  end

  defp add_player_to_btt_room({:error, {:already_started, _}}, match_id, name, socket) do
    match_id |> join_player(socket.assigns.player_id, name)
  end

  defp add_player_to_btt_room(_, _, _, _) do
    "error"
  end

  defp join_player(match_id, player_id, name) do
    BttRoom.join(Records.via_tuple(match_id), player_id, name)
  end

end
