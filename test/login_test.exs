defmodule LoginTest do
  use ExUnit.Case
  alias Tdex, as: T
  setup do
    {:ok, [options: [database: "tdex_test", backoff_type: :stop, max_restarts: 0, pool_size: 1]]}
  end

  test "login password", context do
    Process.flag(:trap_exit, true)
    opts = [protocol: :ws, username: "root", password: "taosdata", port: 6041]
    {:ok, pid} = T.start_link(Keyword.merge opts, context[:options])
    flag = is_pid(pid) and Process.alive?(pid)
    Process.exit(pid, :kill)
    assert flag
  end

  test "login password failure", context do
    Process.flag(:trap_exit, true)
    opts = [protocol: :ws, username: "root", password: "wrong_pass", port: 6041]
    {:ok, pid} = T.start_link(Keyword.merge opts, context[:options])
    flag = is_pid(pid) and Process.alive?(pid)
    Process.exit(pid, :kill)
    assert flag
  end

  # defp assert_start_and_killed(opts) do
  #   Process.flag(:trap_exit, true)

  #   case T.start_link(opts) do
  #     {:ok, pid} -> :ok
  #     {:error, _} -> :ok
  #   end
  # end
end
