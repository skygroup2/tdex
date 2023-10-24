defmodule Tdex.Sql.Rows do
  alias Tdex.{Wrapper, Binary}

  def read_row(res, fieldNames, data \\ []) do
    case Wrapper.taos_fetch_raw_block(res) do
      {:ok, 0, _} ->
        :ok = Wrapper.taos_free_result(res)
        {:ok, %Tdex.Result{code: 0, rows: data}}
      {:ok, _, bin} ->
        padding = <<0::size(128)>>
        dataBlock = <<padding::binary, bin::binary>>
        result = Binary.parse_block(dataBlock, fieldNames)
        read_row(res, fieldNames, data ++ result)
      {:error, reason} -> {:error, reason}
    end
  end
end
