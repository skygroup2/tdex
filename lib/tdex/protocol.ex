defmodule Tdex.Protocol do
  alias Tdex.Query
  use DBConnection

  @impl true
  def connect(opts) do
    opts = Map.new(opts)
    query = %{ id: 0, fieldsCount: 0, fieldsLengths: [], fieldsNames: [], fieldsTypes: [], precision: 0 }
    opts = opts |> Map.put_new(:query, query)
    case Tdex.Connection.new_connect_ws(opts.hostname, opts.port) do
      {:ok, pid} ->
        Tdex.Connection.connect(pid, opts)
        opts = opts |> Map.put_new(:pidWS, pid)
        {:ok, opts}
      {:error, reason} -> {:error, reason}
    end
  end

  @impl true
  @spec checkout(any) :: {:ok, any}
  def checkout(state) do
    {:ok, state}
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
  def handle_prepare(query, opts, state) do
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
  def handle_execute(%{statement: statement} = query, params, _, state) do
    {:ok, dataQuery} = Tdex.Connection.query(state.pidWS, statement)
    {:ok, query, dataQuery, state}
  end

  @impl true
  def handle_close(_, _, s) do
    {:ok, nil, s}
  end

  def handle_info(msg, opts \\ [], s) do
    IO.inspect(msg)
  end
end
