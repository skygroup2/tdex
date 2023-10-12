defmodule Tdex.Protocol do
  use DBConnection
  alias Tdex.{Socket, Common}
  require Logger
  require Skn.Log

  @impl true
  def connect(opts) do
    opts = Map.new(opts)
    case GenServer.start_link(Tdex.Socket, opts) do
      {:error, err} -> {:error, err}
      {:ok, pid} ->
        Logger.info("Connect database successfully")
        {:ok, %{opts | pidSock: pid}}
    end
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
  def disconnect(_, state) do
    Logger.info("Disconnect database")
    Socket.disconnect(state.pidSock)
    :ok
  end

  @impl true
  def handle_status(_opts, state) do
    {:idle, state}
  end

  @impl true
  def handle_prepare(query, opts, state) do
    {:ok, query, state}
  end

  @impl true
  def handle_execute(query, params, _, state) do
    case Common.interpolate_params(query.statement, params) do
      {:ok, query_params} ->
        result = Tdex.Socket.query(state.pidSock, query_params)
        {:ok, query, result, state}
      {:error, _} = error -> error
    end
  end

  @impl true
  def handle_deallocate(_query, _cursor, _opts, state) do
    {:ok, nil, state}
  end

  @impl true
  def handle_close(query, opts, state) do
    disconnect(nil, state)
    {:ok, nil, state}
  end
end
