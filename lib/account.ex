defmodule Account do
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, opts)
  end

  def init(opts) do
    opts = Map.new(opts)
    {:ok, opts}
  end
end
