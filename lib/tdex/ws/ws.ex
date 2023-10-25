defmodule Tdex.WS do
  alias Tdex.WS.{Socket}
  def connect(opts) do
    res = GenServer.start_link(Tdex.WS.Socket, opts);
    IO.inspect(res)
    res
  end

  def query(conn, statement) do
    Socket.query(conn, statement)
  end

  def stop(conn) do
    Socket.stop(conn)
  end
end
