defmodule Tdex do
  alias Tdex.Query
  import Tdex.Utils

  def start_link(opts) do
    opts = default_opts(opts) |> Keyword.put(:pool_size, 2)
    Tdex.Ets.create_table(:tdex)
    DBConnection.start_link(Tdex.Protocol, opts)
  end

  def query(conn, statement, params, opts \\ []) do
    query = %Query{name: "", statement: statement}
    case DBConnection.prepare_execute(conn, query, params, opts) do
      {:ok, _, result} -> {:ok, result}
      {:error, _} = error -> error
    end
  end
end
