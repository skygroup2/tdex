defmodule Tdex do
  use GenServer
  import Tdex.Utils

  def query!(pid, statement, _params) do
    GenServer.call(pid, {:query, statement}, :infinity)
  end

  @spec start_link(keyword) :: :ignore | {:error, any} | {:ok, pid}
  def start_link(opts) do
    opts = default_opts(opts)
    Tdex.Ets.create_table(:tdex)
    GenServer.start_link(__MODULE__, opts)
  end

  def init(opts) do
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

  def handle_cast(msg, state) do
    IO.puts("drop cast: #{inspect msg}")
    {:noreply, state}
  end

  def handle_info(:quit, state) do
    {:stop, :normal, state}
  end

  def handle_info(msg, state) do
    IO.puts("drop info: #{inspect msg}")
    {:noreply, state}
  end

  def terminate(_reason, _state) do
    :ok
  end
end
