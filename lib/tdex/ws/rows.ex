defmodule Tdex.WS.Rows do
  alias Tdex.{WS.Connection, Binary}

  def read_row(pid, dataQuery, timeout, data \\ []) do
    with {:ok, %{"completed" => false}} <- Connection.fetch(pid, dataQuery["id"], timeout),
         {:ok, dataBlock} <- Connection.fetch_block(pid, dataQuery["id"], timeout)
    do
      result = Binary.parse_block(dataBlock, dataQuery["fields_names"])
      read_row(pid, dataQuery, timeout, result ++ data)
    else
      {:ok, _} ->
        Connection.free_result(pid, dataQuery["id"])
        {:ok, data}
      {:error, reason} -> {:error, reason}
    end
  end
end
