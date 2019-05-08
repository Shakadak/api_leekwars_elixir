defmodule Http do
  @moduledoc """
  Facilities for Mint.
  """

  def get(url, opts \\ []) do
    request(Keyword.merge(opts, method: :get, url: url))
  end

  def post(url, opts \\ []) do
    request(Keyword.merge(opts, method: :post, url: url))
  end

  def post(url, content_type, body, opts \\ []) do
    req_opts = [method: :post, url: url, content_type: content_type, body: body]
    request(Keyword.merge(opts, req_opts))
  end

  def put(url, opts \\ []) do
    request(Keyword.merge(opts, method: :put, url: url))
  end

  def put(url, content_type, body, opts \\ []) do
    req_opts = [method: :put, url: url, content_type: content_type, body: body]
    request(Keyword.merge(opts, req_opts))
  end

  def request(opts) do
    opts = Map.new(opts)
    method = String.upcase(to_string(opts.method))
    uri = URI.parse(opts.url)
    headers =
      case opts do
        %{headers: xs, content_type: x} -> [{"content-type", x} | xs]
        %{headers: xs} -> xs
        %{content_type: x} -> [{"content-type", x}]
      end
    headers = Enum.map(headers, fn {k, v} -> {to_string(k), v} end)
    
    body = Map.get(opts, :body, nil)

    scheme = case uri do
      %URI{scheme: "https"} -> :https
      %URI{scheme: "http"} -> :http
    end
    path = case uri do
      %URI{path: path, query: nil} -> path
      %URI{path: path, query: query} -> "#{path}?#{query}"
    end

    opts = Map.drop(opts, [:method, :url, :headers, :content_type, :body])
    opts = Map.to_list(opts)

    {:ok, conn} =
      Mint.HTTP.connect(scheme, uri.host, uri.port, opts)

    {:ok, conn, _request_ref} =
      Mint.HTTP.request(conn, method, path, headers, body)

    {conn, response} = iterate_messages(conn, %{})
    {:ok, _} = Mint.HTTP.close(conn)

    response
  end

  # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

  def fetch!(t, k) do
    case Access.fetch(t, k) do
      {:ok, y} -> y
      :error -> raise(KeyError, key: k, term: t)
    end
  end

  def iterate_messages(conn, %{done: true} = state), do: {conn, state}

  def iterate_messages(conn, state) do
    receive do
      message ->
        {:ok, conn, xs} = Mint.HTTP.stream(conn, message)
        state = Enum.reduce(xs, state, &iterate_responses/2)
        iterate_messages(conn, state)
    end
  end

  def iterate_responses({:status, _, status}, state), do: Map.put(state, :status, status)
  def iterate_responses({:headers, _, headers}, state), do: Map.put(state, :headers, headers)

  def iterate_responses({:data, _, data}, state),
    do: Map.update(state, :data, data, fn acc -> acc <> data end)

  def iterate_responses({:done, _}, state), do: Map.put(state, :done, true)
end
