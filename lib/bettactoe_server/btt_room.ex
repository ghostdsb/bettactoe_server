defmodule BettactoeServer.BttRoom do

  alias BettactoeServer.BttRoom
  @moduledoc """
  BetTacToe keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """

  use GenServer

  @derive Jason.Encoder
  defstruct(
    board: [0,0,0,0,0,0,0,0,0],
    turn: nil,
    move_count: 0,
    match_id: nil,
    player_1: %{
      name: "",
      id: nil,
      bet: 0,
      balance: 100,
      status: "bet"
    },
    player_2: %{
      name: "",
      id: nil,
      bet: 0,
      balance: 100,
      status: "bet"
    },
    player_list: [],
    gameover: %{state: false, winner: nil, pattern: []}
  )

  ##CLIENT API################################
  def start_link(name: room_name, info: info) do
    GenServer.start_link(__MODULE__, info, name: room_name)
  end

  def show_game_state(match_pid) do
    GenServer.call(match_pid, "show_game_state")
  end

  def join(match_pid, player_id, name) do
    GenServer.call(match_pid, {"add_player", player_id, name})
  end

  def bet(match_pid, player_id, bet_value) do
    GenServer.call(match_pid, {"bet", player_id, bet_value})
  end

  def move(match_pid, index) do
    GenServer.call(match_pid, {"move", index})
  end

  #SERVER API################################
  def init(match_id) do
    {:ok, set_match_id(match_id)}
  end

  def handle_call("show_game_state", _from, game_state) do
    {:reply, show_current_game_state(game_state), game_state}
  end

  def handle_call({"add_player", player_id, name}, _from, game_state) do
    game_state = game_state |> add_player_to_game(player_id, name)
    {:reply, game_state, game_state}
  end

  def handle_call({"bet", player_id, bet_value}, _from, game_state) do
    game_state =
    game_state
    |> place_bets(game_state.gameover.state, player_id, bet_value)
    {:reply, game_state, game_state}
  end

  def handle_call({"move", index}, _from, game_state) do
    game_state = game_state |> place_mark(index)
    {:reply, game_state, game_state}
  end

  #HELPER FUNCTIONS################################
  defp set_match_id(match_id) do
    BttRoom.__struct__()
    |> set_match_id_in_gamestate(match_id)
  end

  defp set_match_id_in_gamestate(game_state, match_id) do
    IO.puts("gamestate #{inspect(game_state)}")
    %{game_state | match_id: match_id}
  end

  defp show_current_game_state(game_state) do
    game_state
  end

  defp add_player_to_game(game_state, player_id, name) do
    initialise_player_data(game_state.player_list, game_state, player_id, name)
  end

  defp initialise_player_data([], game_state, player_id, name) do
    %{game_state |
    player_list: [player_id],
    player_1: %{
      name: name,
      id: player_id,
      bet: 0,
      balance: 100,
      status: "bet"
    }
  }
  end

  defp initialise_player_data([player1], game_state, player_id, name) do
    gamestate = %{game_state |
    player_list: [player1, player_id],
    player_2: %{
      name: name,
      id: player_id,
      bet: 0,
      balance: 100,
      status: "bet"
    }
    }
    BettactoeServerWeb.Endpoint.broadcast!("btt:" <> gamestate.match_id, "start_game",
    %{ gamestate: gamestate})
    gamestate
  end

  defp initialise_player_data([_player2, _player1], game_state, _player_id, _name) do
    game_state
  end

  defp place_bets(game_state, true, _player_id, _bet_value) ,do: game_state
  defp place_bets(game_state, false, player_id, bet_value) do
    gs = game_state
    |> update_bet_status(player_id, bet_value)
    |> update_move_status

    IO.puts("gs #{inspect(gs)}")

    gs
  end

  defp update_bet_status(game_state, player_id, bet_value) do
    cond do
      game_state.player_1.id === player_id ->
        cond do
          can_bet?(game_state.player_1, bet_value) ->
            handle_bet_player_1(game_state, player_id, bet_value)
          true -> game_state
        end
      true ->
        cond do
          can_bet?(game_state.player_2, bet_value) ->
            handle_bet_player_2(game_state, player_id, bet_value)
          true -> game_state
        end
    end
  end

  defp handle_bet_player_1(game_state, player_id, bet_value) do
    gs = %{game_state |
      player_1: %{
        id:  player_id,
        bet: bet_value,
        balance: game_state.player_1.balance - bet_value,
        status: "move"
      }
    }
    cond do
      game_state.turn === "continue" -> %{gs | turn: "waiting"}
      true -> gs
    end
  end

  defp handle_bet_player_2(game_state, player_id, bet_value) do
    gs = %{game_state |
      player_2: %{
        id:  player_id,
        bet: bet_value,
        balance: game_state.player_2.balance - bet_value,
        status: "move"
      }
    }
    cond do
      game_state.turn === "continue" -> %{gs | turn: "waiting"}
      true -> gs
    end
  end

  defp update_move_status(game_state) do
    cond do
      can_move?(game_state) -> cond do
        bet_winner(game_state) === 1 -> %{game_state | turn: hd(game_state.player_list) }
        bet_winner(game_state) === 2 -> %{game_state | turn: hd(tl(game_state.player_list)) }
        true -> %{game_state |
          player_1: %{
            id:  game_state.player_1.id,
            bet: 0,
            balance: game_state.player_1.balance,
            status: "bet"
          },
          player_2: %{
            id:  game_state.player_2.id,
            bet: 0,
            balance: game_state.player_2.balance,
            status: "bet"
          },
          turn: "continue"
        }
      end
      true -> game_state
    end
  end

  defp can_bet?(player_map, bet_value) do
    player_map.status === "bet" && player_map.balance >= bet_value
  end

  defp can_move?(game_state) do
    game_state.player_1.status === "move" && game_state.player_2.status === "move"
  end

  defp bet_winner(game_state) do
    cond do
      game_state.player_1.bet > game_state.player_2.bet -> 1
      game_state.player_1.bet < game_state.player_2.bet -> 2
      true -> cond do
        game_state.player_1.balance > game_state.player_2.balance -> 2
        game_state.player_1.balance < game_state.player_2.balance -> 1
        true -> nil
      end
    end
  end

  defp place_mark(game_state, index) ,do: place_mark(game_state, index, can_move?(game_state), Enum.at(game_state.board, index-1))
  defp place_mark(game_state, index, true, 0) do
    player_id = game_state.turn
    new_board = game_state.board |> List.update_at(index-1, fn _ -> player_id end)
    player_1_details = %{game_state.player_1 | status: "bet"}
    player_2_details = %{game_state.player_2 | status: "bet"}
    game_state =
    %{game_state |
      board: new_board,
      player_1: player_1_details,
      player_2: player_2_details,
      turn: nil
    }
    gameover_status = is_gameover(game_state.board, player_id)
    game_state =
    cond do
      gameover_status.result -> %{game_state | gameover: %{state: true, winner: player_id, pattern: gameover_status.pattern}}
      true -> game_state
    end
    game_state
  end
  defp place_mark(game_state, _index, true, _), do: game_state
  defp place_mark(game_state, _index, false, _), do: game_state


  defp is_gameover([x,x,x,_,_,_,_,_,_], x) ,do: %{result: true, pattern: [0,1,2]}
  defp is_gameover([_,_,_,x,x,x,_,_,_], x) ,do: %{result: true, pattern: [3,4,5]}
  defp is_gameover([_,_,_,_,_,_,x,x,x], x) ,do: %{result: true, pattern: [6,7,8]}
  defp is_gameover([x,_,_,x,_,_,x,_,_], x) ,do: %{result: true, pattern: [0,3,6]}
  defp is_gameover([_,x,_,_,x,_,_,x,_], x) ,do: %{result: true, pattern: [1,4,7]}
  defp is_gameover([_,_,x,_,_,x,_,_,x], x) ,do: %{result: true, pattern: [2,5,8]}
  defp is_gameover([x,_,_,_,x,_,_,_,x], x) ,do: %{result: true, pattern: [0,4,8]}
  defp is_gameover([_,_,x,_,x,_,x,_,_], x) ,do: %{result: true, pattern: [2,4,6]}
  defp is_gameover(_board, _player_id) ,do: %{result: false, pattern: []}

end
