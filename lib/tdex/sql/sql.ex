defmodule Tdex.Sql do
  alias Tdex.SQL

  def connect(opts) do
    GenServer.start_link(Tdex.SQL.Async, opts);
  end

  def query(conn, statement) do
    SQL.Async.query_async(conn, statement, 5000)
  end

  def stop(conn) do
    SQL.Async.stop(conn)
  end
end
