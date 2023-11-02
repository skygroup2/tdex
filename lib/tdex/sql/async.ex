defmodule Tdex.SQL.Async do
  use GenServer
  require Logger
  require Skn.Log
  alias Tdex.{Wrapper, Binary}

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts);
  end

  def query_async(pid, statement, timeout \\ 5000), do: GenServer.call(pid, {:query_async, statement}, timeout)
  def stop(pid), do: GenServer.cast(pid, :stop)

  def init(opts) do
    state = %{
      conn: nil,
      fieldNames: [],
      res: nil,
      result: [],
      from: nil
    }

    # hostname = ~c(#{opts.hostname})
    # username = ~c(#{opts.username})
    # password = ~c(#{opts.password})
    # database = ~c(#{opts.database})
    # port = opts.port

    # case Tdex.Wrapper.taos_connect(hostname, username, password, database, port) do
    #   {:ok, conn} -> {:ok, %{state | conn: conn}}
    #   {:error, reason} ->  {:stop, reason}
    # end

    case Tdex.Wrapper.taos_connect('localhost', 'root', 'taosdata', 'test', 6030) do
      {:ok, conn} -> {:ok, %{state | conn: conn}}
      {:error, reason} ->  {:stop, reason}
    end
  end

  def handle_call({:query_async, sql}, from, state) do
    Tdex.Wrapper.taos_query_a(state.conn, 1, ~c(#{sql}), self())
    {:noreply, %{state| from: from}}
  end

  def handle_info({:res_async, req_id, res}, state) do
    {:ok, field} = Wrapper.taos_fetch_fields(res)
    fieldNames = Binary.parse_field(field, [])
    Tdex.Wrapper.taos_fetch_raw_block_a(res, req_id, self())
    {:noreply, %{state| fieldNames: fieldNames, res: res}}
  end

  def handle_info({:fetch_raw_async, req_id, numOfRows}, state) do
    if(numOfRows == 0) do
      :ok = Wrapper.taos_free_result(state.res)
      GenServer.reply(state.from, {:ok, state.result})
      {:noreply, state}
    else
      {:ok, bin} = Tdex.Wrapper.taos_get_raw_block(state.res)
      padding = <<0::size(128)>>
      dataBlock = <<padding::binary, bin::binary>>
      result = Binary.parse_block(dataBlock, state.fieldNames, state.result)
      Tdex.Wrapper.taos_fetch_raw_block_a(state.res, req_id, self())
      {:noreply, %{state | result: result}}
    end
  end

  def handle_info({:error, req_id, reason}, state) do
    GenServer.reply(state.from, {:error, reason})
    {:noreply, state}
  end

  def handle_info(msg, state) do
    Skn.Log.error("drop info: #{inspect(msg)}")
    {:noreply, state}
  end

  def handle_cast(:stop, state) do
    Wrapper.taos_close(state.conn)
    Wrapper.taos_cleanup()
  end
end
