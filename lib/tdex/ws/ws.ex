defmodule Tdex.WS do
  alias Tdex.WS.{Socket}
  def connect(opts) do
    GenServer.start_link(Tdex.WS.Socket, opts)
  end

  def query(conn, statement) do
    Socket.query(conn, statement)
  end

  def stop(conn) do
    Socket.stop(conn)
  end

  def stop_query(_conn) do
    raise "current, stop_query is not supported for ws"
  end
end
