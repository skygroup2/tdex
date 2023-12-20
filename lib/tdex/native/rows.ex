defmodule Tdex.Native.Rows do
  alias Tdex.{Wrapper, Binary}

  def read_row(res, [], _precision, _data) do
    {:ok, affected_rows} = Wrapper.taos_affected_rows(res)
    {:ok, %Tdex.Result{code: 0, rows: [], affected_rows: affected_rows}}
  end

  def read_row(res, fieldNames, precision, data) do
    case Wrapper.taos_fetch_raw_block(res) do
      {:ok, 0, _} ->
        {:ok, affected_rows} = Wrapper.taos_affected_rows(res)
        {:ok, %Tdex.Result{code: 0, rows: Enum.reverse(data), affected_rows: affected_rows}}
      {:ok, _, bin} ->
        padding = <<0::size(128)>>
        dataBlock = <<padding::binary, bin::binary>>
        result = Binary.parse_block(dataBlock, fieldNames, precision, data)
        read_row(res, fieldNames, precision, result)
      {:error, reason} -> {:error, reason}
    end
  end
end
