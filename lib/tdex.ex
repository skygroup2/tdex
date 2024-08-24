defmodule Tdex do
  use Application
  alias TDex.Query
  import TDex.Utils

  def start(_type, _args) do
    TDex.Ets.create_table()
    :logger.add_handlers(:tdex)
    Supervisor.start_link([], strategy: :one_for_one)
  end

  def start_link() do
    opts = Application.get_env(:tdex, TDex.Repo) |> default_opts()
    DBConnection.start_link(TDex.DBConnection, opts)
  end

  def start_link(opts) do
    opts = default_opts(opts)
    DBConnection.start_link(TDex.DBConnection, opts)
  end

  def query(conn, statement, params, opts \\ []) do
    query = %Query{name: "", statement: statement}
    case DBConnection.prepare_execute(conn, query, params, opts) do
      {:ok, query, result} -> {:ok, query, result}
      {:error, _} = error -> error
    end
  end

  def query!(conn, statement, params, opts \\ []) do
    query = %Query{name: "", statement: statement}
    case DBConnection.prepare_execute(conn, query, params, opts) do
      {:ok, _, result} -> result
      {:error, error} -> raise error
    end
  end

  def execute(conn, statement, params, opts \\ []) do
    query = %Query{name: "", statement: statement}
    DBConnection.execute(conn, query, params, opts)
  end

  def execute!(conn, statement, params, opts \\ []) do
    query = %Query{name: "", statement: statement}
    DBConnection.execute!(conn, query, params, opts)
  end
end
