defmodule Farmer do
  use GenServer

  ### API ###

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, opts)
  end

  def authentication_headers(name), do: GenServer.call(name, :authentication_headers)
  def cookies(name), do: GenServer.call(name, :cookies)
  def leeks(name), do: GenServer.call(name, :leeks)
  def merge_cookies(name, cookies), do: GenServer.cast(name, {:merge_cookies, cookies})

  ### IMPL ###

  def init(opts) do
    state = Map.new(opts)
    {:ok, state, {:continue, :login}}
  end

  def handle_continue(:login, state) do
    %{status: 200, headers: headers, data: data} =
      Api.Farmer.login(state.login, state.password, keep_connected: true)

    cookies =
      headers
      |> Enum.filter(fn {k, _} -> k == "set-cookie" end)
      |> Enum.map(fn {_, v} -> SetCookie.parse(v) end)

    state = Map.put(state, :cookies, cookies)

    farmer = Map.take(data.farmer, [:talent, :in_garden, :habs, :tournament, :name, :login, :id, :fights])
    state = Map.put(state, :farmer, farmer)

    leeks = Enum.map(data.farmer.leeks, fn {_, leek} ->
      leek = Map.put(leek, :farmer, state.name)
      leek = Map.update!(leek, :name, &String.to_atom/1)
      {:ok, _} = Leek.start_link(Map.to_list(leek))
      leek.name
    end)
    state = Map.put(state, :leeks, leeks)

    {:noreply, state}
  end

  def handle_call(:authentication_headers, _from, state) do
    cookies =
      Map.new(state.cookies, fn %{key: k, value: v} -> {String.to_atom(k), v} end)

    cookie = Enum.map_join(cookies, "; ", fn {k, v} -> "#{k}=#{v}" end)
    headers = [cookie: cookie, authorization: "Bearer $"]

    {:reply, headers, state}
  end
  def handle_call(:cookies, _from, state), do: {:reply, state.cookies, state}
  def handle_call(:leeks, _from, state), do: {:reply, state.leeks, state}

  def handle_cast({:merge_cookies, cookies}, state) do
    state =
      Map.update!(state, :cookies, fn acc ->
        acc = Map.new(acc, fn x -> {x.key, x} end)
        cookies = Map.new(cookies, fn x -> {x.key, x} end)
        Map.values(Map.merge(acc, cookies))
      end)
    {:noreply, state}
  end
end
