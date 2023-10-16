defmodule Tdex.Utils do
  def default_opts(opts) do
    opts
    |> Keyword.put_new(:username, "root")
    |> Keyword.put_new(:password, "taosdata")
    |> Keyword.put_new(:database, "taos")
    |> Keyword.put_new(:hostname, "localhost")
    |> Keyword.put_new(:query, %{ id: 0, fieldsCount: 0, fieldsLengths: [], fieldsNames: [], fieldsTypes: [], precision: 0 })
    |> Keyword.put_new(:pid, 0)
    |> Keyword.put_new(:port, 6041)
    |> Keyword.update(:protocol, Tdex.WS, &handle_protocol/1)
    |> Keyword.update!(:port, &normalize_port/1)
    |> Enum.reject(fn {_k, v} -> is_nil(v) end)
  end

  defp normalize_port(port) when is_binary(port), do: String.to_integer(port)
  defp normalize_port(port), do: port

  defp handle_protocol("sql"), do: Tdex.Sql
  defp handle_protocol("ws"), do: Tdex.WS
end
