defmodule TDex.WS do
  alias TDex.WS.{Socket}
  def connect(opts) do
    GenServer.start_link(TDex.WS.Socket, opts);
  end

  def query(conn, statement) do
    Socket.query(conn, statement)
  end

  def stop(conn) do
    Socket.stop(conn)
  end
end
