defmodule Tdex.Async do
  use GenServer
  require Logger
  require Skn.Log
  alias Tdex.{Wrapper, Binary}


  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts);
  end

  def query_a(pid, sql), do: GenServer.call(pid, {:query_a, sql})

  def init(opts) do
    state = %{
      fieldNames: [],
      res: nil,
      result: [],
      from: nil
    }

    {:ok, state}
  end

  def handle_call({:query_a, sql}, from, state) do
    { ok, connect } = Tdex.Wrapper.taos_connect('localhost', 'root', 'taosdata', 'test', 6030)
    Tdex.Wrapper.taos_query_a(connect, sql, self())
    # IO.inspect(from)
    Process.send_after(self(), {:reply, from}, 1_000_000)
    {:noreply, %{state| from: from}}
  end

  def handle_info({:res_async, res}, state) do
    {:ok, field} = Wrapper.taos_fetch_fields(res)
    fieldNames = Binary.parse_field(field, [])

    Tdex.Wrapper.taos_fetch_raw_block_a(res, self())
    {:noreply, %{state| fieldNames: fieldNames, res: res}}
  end

  def handle_info({:fetch_raw_async, numOfRows}, state) do
    IO.puts("fetch_raw_async #{numOfRows}")

    if(numOfRows == 0) do
      :ok = Wrapper.taos_free_result(state.res)
      # IO.inspect(state.result)
      GenServer.reply(state.from, state.result)
      {:noreply, state}
    else
      {:ok, bin} = Tdex.Wrapper.taos_get_raw_block(state.res)
      padding = <<0::size(128)>>
      dataBlock = <<padding::binary, bin::binary>>
      result = Binary.parse_block(dataBlock, state.fieldNames)
      Tdex.Wrapper.taos_fetch_raw_block_a(state.res, self())
      temp = state.result
      {:noreply, %{state | result: temp ++ result}}
    end
  end

  def handle_info(msg, state) do
    Skn.Log.error("drop info: #{inspect(msg)}")
    {:noreply, state}
  end

end
