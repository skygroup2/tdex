defmodule Tdex.WS.Socket do
  use GenServer
  alias Tdex.{WS.Connection, WS.Rows}

  def init(opts) do
    opts = %{
      hostname: opts.hostname,
      port: opts.port,
      username: opts.username,
      password: opts.password,
      database: opts.database,
      timeout: opts.timeout
    }

    state = %{
      pidWS: nil,
      timeout: opts.timeout
    }

    with {:ok, pid} <- Connection.new_connect_ws(opts.hostname, opts.port),
         {:ok, _} <- Connection.connect(pid, opts)
    do
      {:ok, %{state | pidWS: pid}}
    else
      {:error, _} = error ->
        error
    end
  end

  def query(pid, statement) do
    GenServer.call(pid, {:query, statement}, :infinity)
  end

  def stop(pid) do
    GenServer.stop(pid, :gun_down, :infinity)
  end

  def handle_call({:query, statement}, _from, state) do
    result = case Connection.query(state.pidWS, statement, state.timeout) do
      {:ok, dataQuery} ->
        if dataQuery["fields_lengths"] do
          {:ok, data} = Rows.read_row(state.pidWS, dataQuery, state.timeout, [])
          result = %Tdex.Result{code: dataQuery["code"], req_id: dataQuery["req_id"], rows: data, affected_rows: dataQuery["affected_rows"], message: dataQuery["message"]}
          {:ok, result}
        else
          {:ok, %Tdex.Result{code: dataQuery["code"], req_id: dataQuery["req_id"], rows: [], affected_rows: dataQuery["affected_rows"], message: dataQuery["message"]}}
        end
      {:error, _ } = error -> error
    end

    {:reply, result, state}
  end

  def handle_info({:gun_down, _, :ws, :closed, []}, state) do
    {:stop, :gun_down, state}
  end

  def terminate(_reason, state) do
    IO.puts("shutdown pid #{inspect(state.pidWS)}")
    :gun.shutdown(state.pidWS)
  end
end
