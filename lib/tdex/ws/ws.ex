defmodule Tdex.WS do
  def connect(opts) do
    GenServer.start_link(Tdex.WS.Socket, opts);
  end

  def query(conn, statement) do
    Tdex.WS.Socket.query(conn, statement)
  end

  def disconnect(_) do

  end
end
