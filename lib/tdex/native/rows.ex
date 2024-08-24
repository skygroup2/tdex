defmodule TDex.Native.Rows do
  alias TDex.{Wrapper, Binary}

  def read_row(res, [], _data) do
    {:ok, affected_rows} = Wrapper.taos_affected_rows(res)
    {:ok, %TDex.Result{code: 0, rows: [], affected_rows: affected_rows}}
  end

  def read_row(res, fieldNames, data) do
    case Wrapper.taos_fetch_raw_block(res) do
      {:ok, 0, _} ->
        :ok = Wrapper.taos_free_result(res)
        {:ok, %TDex.Result{code: 0, rows: Enum.reverse(data)}}
      {:ok, _, bin} ->
        padding = <<0::size(128)>>
        dataBlock = <<padding::binary, bin::binary>>
        result = Binary.parse_block(dataBlock, fieldNames, data)
        read_row(res, fieldNames, result)
      {:error, reason} -> {:error, reason}
    end
  end


end
