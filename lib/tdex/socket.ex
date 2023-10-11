defmodule Tdex.Socket do
  use GenServer
  alias Tdex.Connection

  def init(opts) do
    opts = %{
      hostname: opts.hostname,
      port: opts.port,
      username: opts.username,
      password: opts.password,
      database: opts.database
    }

    state = %{
      # opts: opts,
      pidWS: nil,
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

  # def connect(pid) do
  #   GenServer.call(pid, :conn, :infinity)
  # end

  def query(pid, statement) do
    GenServer.call(pid, {:query, statement}, :infinity)
  end

  def disconnect(pid) do
    GenServer.call(pid, :disconnect, :infinity)
  end

  # def handle_call(:conn, _from, state) do
  #   case Tdex.Connection.connect(state.pidWS, state.opts) do
  #     {:error, err} -> {:error, err, state}
  #     {:ok, res} -> {:reply, res, state}
  #   end
  # end

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

  def handle_call(:disconnect, _from, state) do
    :gun.close(state.pidWS)
    {:reply, :disconnect, state}
  end
end
