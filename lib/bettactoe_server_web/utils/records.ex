defmodule BettactoeServerWeb.Utils.Records do

  def via_tuple(pname) do
    {:via, Registry, {BettactoeServerWeb.GameRegistry, pname}}
  end

  def is_process_registered(pname) do
    Registry.lookup(BettactoeServerWeb.GameRegistry, pname)
  end
end
