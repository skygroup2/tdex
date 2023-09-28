defmodule TdexTest do
  use ExUnit.Case
  doctest Tdex

  test "greets the world" do
    assert Tdex.hello() == :world
  end
end
