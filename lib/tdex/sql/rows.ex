defmodule Tdex.Sql.Rows do
  alias Tdex.{Wrapper, Binary}

  def read_row(res, fieldNames, data \\ []) do
    { :ok, numOfRows, bin } = Wrapper.taos_fetch_raw_block(res)
    if numOfRows == 0 do
      Wrapper.taos_free_result(res)
      {:ok, %Tdex.Result{code: 0, rows: data}}
    else
      padding = <<0::size(128)>>
      dataBlock = <<padding::binary, bin::binary>>
      result = Binary.parse_block(dataBlock, fieldNames)
      read_row(res, fieldNames, data ++ result)
    end
  end
end
