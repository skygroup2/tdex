defmodule Tdex.WS.Rows do
  alias Tdex.{WS.Connection, Binary}

  def read_row(pid, dataQuery, timeout, data \\ []) do
    {:ok, dataFetch} = Connection.fetch(pid, dataQuery["id"], timeout)
    if dataFetch["completed"] do
      {:ok, data}
    else
      {:ok, dataBlock} = Connection.fetch_block(pid, dataQuery["id"], timeout)
      result = Binary.parse_block(dataBlock, dataQuery["fields_names"])
      read_row(pid, dataQuery, timeout, data ++ result)
    end
  end
end
