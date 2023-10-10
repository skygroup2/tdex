defmodule Tdex.Socket do
  use GenServer

  def init(opts) do
    opts = %{
      hostname: opts.hostname,
      port: opts.port,
      username: opts.username,
      password: opts.password,
      database: opts.database
    }

    state = %{
      opts: opts,
      pidWS: nil,
      result: nil
    }

    case Tdex.Connection.new_connect_ws(opts.hostname, opts.port) do
      {:ok, pid} -> {:ok, %{state | pidWS: pid} }
      {:error, reason} -> {:error, reason}
    end
  # catch _, ex -> {:error, ex}
  end

  def connect(pid) do
    GenServer.call(pid, :conn, :infinity)
  end

  def query(pid, statement) do
    GenServer.call(pid, {:query, statement}, :infinity)
  end

  def handle_call(:conn, _from, state) do
    res = Tdex.Connection.connect(state.pidWS, state.opts)
    {:reply, res, state}
  end

  def handle_call({:query, statement}, _from, state) do
    {:ok, dataQuery} = Tdex.Connection.query(state.pidWS, statement)

    result = if dataQuery["code"] != 0 do
      %{code: dataQuery["code"], message: dataQuery["message"]}
    else
      if dataQuery["fields_lengths"] do
        {:ok, data} = Tdex.Connection.read_row(state.pidWS, dataQuery, [])
        %{code: dataQuery["code"], rows: data, message: dataQuery["message"]}
      else
        %{code: dataQuery["code"], affected_rows: dataQuery["affected_rows"], message: dataQuery["message"]}
      end
    end

    {:reply, result, state}
  end
end
