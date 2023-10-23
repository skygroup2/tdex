defmodule Tdex.WS.Rows do
  alias Tdex.{WS.Connection, Binary}

  def read_row(pid, dataQuery, timeout, data \\ []) do
    dataFetch = Connection.fetch(pid, dataQuery["id"], timeout)
    handle_fetch(pid, dataQuery, timeout, dataFetch, data)
  end

  defp handle_fetch(_, _, _, {:error, reason}, _) do
    {:error, reason}
  end

  defp handle_fetch(pid, dataQuery, _, {:ok, %{"completed" => true}}, data) do
    Connection.free_result(pid, dataQuery["id"])
    {:ok, data}
  end

  defp handle_fetch(pid, dataQuery, timeout, {:ok, _}, data) do
    case Connection.fetch_block(pid, dataQuery["id"], timeout) do
      {:ok, dataBlock} ->
        result = Binary.parse_block(dataBlock, dataQuery["fields_names"])
        read_row(pid, dataQuery, timeout, result ++ data)
      {:error, reason} -> {:error, reason}
    end
  end
end
