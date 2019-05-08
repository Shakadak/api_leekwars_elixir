defmodule Leek do
  use GenServer

  ### API ###

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, opts)
  end

  def fight(name, opponent_id), do: GenServer.call(name, {:fight, opponent_id})
  def opponents(name), do: GenServer.call(name, :opponents)

  ### IMPL ###

  def init(opts) do
    state = Map.new(opts)
    state = Map.take(state, [:name, :id, :farmer])
    {:ok, state}
  end

  def handle_call(:opponents, _from, state) do
    headers = Farmer.authentication_headers(state.farmer)

    %{status: 200, headers: headers, data: data} =
      Api.Garden.get_leek_opponents(state.id, headers: headers)

    cookies =
      headers
      |> Enum.filter(fn {k, _} -> k == "set-cookie" end)
      |> Enum.map(fn {_, v} -> SetCookie.parse(v) end)
    _ = Farmer.merge_cookies(state.farmer, cookies)

    opponents = Enum.map(data.opponents, fn x -> Map.drop(x, [:hat, :skin]) end)

    {:reply, opponents, state}
  end

  def handle_call({:fight, opponent}, _from, state) do
    headers = Farmer.authentication_headers(state.farmer)

    %{status: 200, headers: headers, data: data} =
      Api.Garden.start_solo_fight(state.id, opponent, headers: headers)

    cookies =
      headers
      |> Enum.filter(fn {k, _} -> k == "set-cookie" end)
      |> Enum.map(fn {_, v} -> SetCookie.parse(v) end)
    _ = Farmer.merge_cookies(state.farmer, cookies)

    state = Map.put(state, :current_fight, data.fight)

    {:reply, data.fight, state}
  end
end
