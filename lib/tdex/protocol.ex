defmodule Tdex.Protocol do
  use DBConnection

  @impl true
  def connect(opts) do
    opts = Map.new(opts)
    {:ok, pid} = GenServer.start_link(Tdex.Socket, opts)
    {:ok, _} = Tdex.Socket.connect(pid)
    {:ok, %{opts | pidSock: pid}}
  end

  @impl true
  def checkout(state) do
    {:ok, state}
  end

  @impl true
  def handle_rollback(_opts, state) do
    {:ok, nil, state}
  end


  @impl true
  def handle_begin(_opts, state) do
    {:ok, nil, state}
  end

  @impl true
  def handle_fetch(_query, _cursor, _opts, state) do
    {:cont, nil, state}
  end

  @impl true
  def handle_declare(query, _params, _opts, state) do
    {:ok, query, nil, state}
  end

  @impl true
  def handle_commit(_opts, state) do
    {:ok, nil, state}
  end

  @impl true
  def ping(state) do
    {:ok, state}
  end

  @impl true
  def disconnect(_, _state) do
    IO.inspect("disconnect")
    :ok
  end

  @impl true
  def handle_status(_opts, state) do
    {:idle, state}
  end

  @impl true
  def handle_prepare(query, _opts, state) do
    {:ok, query, state}
  end

  def recv_ws() do
    receive do
      { :gun_ws, _pid, _ref, {:text, data} } -> {:ok, Jason.decode!(data)}
      { :gun_ws, _pid, _ref, {:binary, data} } -> {:ok, (data)}
    after 5000 -> {:error, :timeout}
    end
  end

  @impl true
  def handle_execute(%{statement: statement} = query, _params, _, state) do
    result = Tdex.Socket.query(state.pidSock, statement)
    {:ok, query, result, state}
  end

  @impl true
  def handle_deallocate(_query, _cursor, _opts, state) do
    {:ok, nil, state}
  end

  @impl true
  def handle_close(_, _, s) do
    {:ok, nil, s}
  end

  def handle_info(msg, _opts \\ [], _s) do
    IO.inspect(msg)
  end
end
