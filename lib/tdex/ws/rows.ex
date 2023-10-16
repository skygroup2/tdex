defmodule Tdex.WS.Rows do
  alias Tdex.{WS.Connection, Binary}

  def read_row(pid, dataQuery, data) do
    {:ok, dataFetch} = Connection.fetch(pid, dataQuery["id"])
    if dataFetch["completed"] do
      {:ok, List.flatten(data)}
    else
      {:ok, dataBlock} = Connection.fetch_block(pid, dataQuery["id"])
      IO.inspect({Base.encode16(dataBlock)})
      result = Binary.parse_block(dataBlock, dataQuery["fields_names"])
      read_row(pid, dataQuery, [result|data])
    end
  end
end
