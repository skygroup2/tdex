defmodule Tdex.Utils do
  def default_opts(opts) do
    {field, value} = extract_host(System.get_env("TDHOST"))
    opts
    |> Keyword.put_new(:username, System.get_env("TDUSER") || System.get_env("USER"))
    |> Keyword.put_new(:password, System.get_env("TDPASSWORD"))
    |> Keyword.put_new(:database, System.get_env("TDDATABASE"))
    |> Keyword.put_new(field, value)
    |> Keyword.put_new(:port, System.get_env("TDPORT"))
    |> Keyword.update!(:port, &normalize_port/1)
    |> Enum.reject(fn {_k, v} -> is_nil(v) end)
  end

  defp extract_host(host), do: {:hostname, host || "localhost"}

  defp normalize_port(port) when is_binary(port), do: String.to_integer(port)
  defp normalize_port(port), do: port
end
