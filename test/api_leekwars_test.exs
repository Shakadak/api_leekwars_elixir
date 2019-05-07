defmodule ApiLeekwarsTest do
  use ExUnit.Case
  doctest ApiLeekwars

  test "greets the world" do
    assert ApiLeekwars.hello() == :world
  end
end
