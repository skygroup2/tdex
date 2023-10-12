defmodule Tdex do
  use Application
  alias Tdex.Query
  import Tdex.Utils

  def start(_type, _args) do
    Tdex.Ets.create_table(:tdex)
    :logger.add_handlers(:tdex)
    Supervisor.start_link([], strategy: :one_for_one)
  end

  def start_link(opts) do
    opts = default_opts(opts)
    DBConnection.start_link(Tdex.Protocol, opts)
  end

  def query(conn, statement, params, opts \\ []) do
    query = %Query{name: "", statement: statement}
    IO.puts("query --> #{inspect(params)}")
    case DBConnection.prepare_execute(conn, query, params, opts) do
      {:ok, _, result} -> {:ok, result}
      {:error, _} = error -> error
    end
  end

  def query!(conn, statement, params, opts \\ []) do
    query = %Query{name: "", statement: statement}
    case DBConnection.prepare_execute(conn, query, params, opts) do
      {:ok, _, result} -> result
      {:error, _} = error -> raise error
    end
  end

  def execute(conn, query, params, opts \\ []) do
    DBConnection.execute(conn, query, params, opts)
  end

  def execute!(conn, query, params, opts \\ []) do
    DBConnection.execute!(conn, query, params, opts)
  end

  def close(conn, query, opts \\ []) do
    with {:ok, _} <- DBConnection.close(conn, query, opts) do
      :ok
    end
  end

  def close!(conn, query, opts \\ []) do
    DBConnection.close!(conn, query, opts)
    :ok
  end
end
