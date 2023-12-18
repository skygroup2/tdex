defmodule Tdex.Utils do
  def default_opts(opts) do
    opts
    |> Keyword.put_new(:username, "root")
    |> Keyword.put_new(:password, "taosdata")
    |> Keyword.put_new(:database, "taos")
    |> Keyword.put_new(:hostname, "localhost")
    |> Keyword.put_new(:timeout, 10000)
    |> Keyword.put_new(:conn, 0)
    |> Keyword.put_new(:port, default_port(Keyword.get(opts, :protocol)))
    |> Keyword.update(:protocol, Tdex.Native, &handle_protocol/1)
    |> Keyword.update!(:port, &normalize_port/1)
    |> Enum.reject(fn {_k, v} -> is_nil(v) end)
  end

  defp normalize_port(port) when is_binary(port), do: String.to_integer(port)
  defp normalize_port(port), do: port

  defp handle_protocol(:native), do: Tdex.Native
  defp handle_protocol(:ws), do: Tdex.WS

  defp default_port(:native), do: 6030
  defp default_port(:ws), do: 6041
end
