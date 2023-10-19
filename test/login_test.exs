defmodule LoginTest do
  use ExUnit.Case
  import ExUnit.CaptureLog
  alias Tdex, as: T
  setup do
    {:ok, [options: [database: "test", backoff_type: :stop, max_restarts: 0]]}
  end

  test "login password", context do
    Process.flag(:trap_exit, true)
    opts = [protocol: "ws", username: "root", password: "taosdata", port: 6041]
    assert {:ok, pid} = T.start_link(opts ++ context[:options])
    assert {:ok, %Tdex.Query{}, %T.Result{}} = T.query(pid, "SELECT 123", [])
    TSQL.cmd(["-s", "DROP DATABASE IF EXISTS postgrex_test;"])
  end

  # test "login password failure", context do
  #   Process.flag(:trap_exit, true)
  #   opts = [protocol: "ws", username: "root", password: "taosdata", port: 6041]
  #   assert {:ok, pid} = T.start_link(opts ++ context[:options])
  #   assert {:error, _} = T.query(pid, "SELECT 123", [])
  # end

  # defp assert_start_and_killed(opts) do
  #   Process.flag(:trap_exit, true)

  #   case T.start_link(opts) do
  #     {:ok, pid} -> :ok
  #     {:error, _} -> :ok
  #   end
  # end
end
