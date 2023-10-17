defmodule Tdex.DBConnection do
  use DBConnection
  alias Tdex.Common
  require Logger
  require Skn.Log

  @impl true
  def connect(opts) do
    opts = Map.new(opts)
    case opts.protocol.connect(opts) do
      {:ok, pid} -> {:ok, %{opts | conn: pid}}
      {:error, _} = error -> error
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
  def disconnect(_, _state) do
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

  @impl true
  def handle_execute(query, params, _, state) do
    with {:ok, query_params} <- Common.interpolate_params(query.statement, params),
         {:ok, result} <- state.protocol.query(state.conn, query_params)
    do
      {:ok, query, result, state}
    else
      {:error, error} -> {:error, error, state}
    end
  end

  @impl true
  def handle_deallocate(_query, _cursor, _opts, state) do
    {:ok, nil, state}
  end

  @impl true
  def handle_close(_query, _opts, state) do
    disconnect(nil, state)
    {:ok, nil, state}
  end
end
