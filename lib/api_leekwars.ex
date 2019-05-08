defmodule Api.Farmer do
  @base "https://leekwars.com/api/farmer"

  def login(login, password, opts \\ []) do
    credentials = %{
      login: login,
      password: password,
      keep_connected: Keyword.get(opts, :keep_connected, false),
    }

    content_type = "application/x-www-form-urlencoded"
    body = URI.encode_query(credentials)

    # Can't seem to verify with leekwars' certificate.
    opts = [transport_opts: [verify: :verify_none]] ++ opts

    response = Http.post("#{@base}/login", content_type, body, opts)
    Map.update!(response, :data, fn data -> Poison.decode!(data, keys: :atoms) end)
  end

  def login_token(login, password, opts \\ []) do
    credentials = %{
      login: login,
      password: password
    }

    content_type = "application/x-www-form-urlencoded"
    body = URI.encode_query(credentials)

    # Can't seem to verify leekwars' certificate.
    opts = [transport_opts: [verify: :verify_none]] ++ opts

    response = Http.post("#{@base}/login-token", content_type, body, opts)
    Map.update!(response, :data, fn data -> Poison.decode!(data, keys: :atoms) end)
  end
end

defmodule Api.Garden do
  @base "https://leekwars.com/api/garden"
  def get_leek_opponents(leek, opts \\ []) do
    # Can't seem to verify leekwars' certificate.
    opts = [transport_opts: [verify: :verify_none]] ++ opts

    response = Http.get("#{@base}/get-leek-opponents/#{leek}", opts)
    Map.update!(response, :data, fn data -> Poison.decode!(data, keys: :atoms) end)
  end

  def start_solo_fight(leek, opponent, opts \\ []) do
    # Can't seem to verify leekwars' certificate.
    opts = [transport_opts: [verify: :verify_none]] ++ opts

    payload = %{leek_id: leek, target_id: opponent}
    content_type = "application/x-www-form-urlencoded"
    body = URI.encode_query(payload)

    response = Http.post("#{@base}/start-solo-fight", content_type, body, opts)
    Map.update!(response, :data, fn data -> Poison.decode!(data, keys: :atoms) end)
  end
end
