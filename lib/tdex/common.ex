defmodule Tdex.Common do
  @max_taos_sql_len 1048576

  def interpolate_params(query, args) do
    count = String.split(query, "?") |> length()
    if count - 1 != length(args) do
      {:error, :arg_not_valid }
    else
      {:ok, check_statement_length(query, args, "")}
    end
  end

  defp check_statement_length(query, args, result) do
    if String.length(query) > @max_taos_sql_len do
      {:error, :sql_statement_too_long}
    else
      interpolate(query, args, result)
    end
  end

  defp interpolate("", [], result), do: result
  defp interpolate(query, [], result), do: result <> query
  defp interpolate(query, [arg | tail], result) when byte_size(result) <= @max_taos_sql_len do
    value = parse_type(arg)
    case value do
      {:ok, val} ->
        [query, remaining] = String.split(query, "?", parts: 2)
        interpolate(remaining, tail, result <> query <> val)
      {:error, _} = error -> error
    end
  end

  defp parse_type(val) when is_integer(val), do: {:ok, Integer.to_string(val)}
  defp parse_type(val) when is_float(val), do: {:ok, Float.to_string(val)}
  defp parse_type(val) when is_boolean(val), do: {:ok, to_string(val)}
  defp parse_type(val) when is_binary(val), do: {:ok, "'#{val}'"}
  defp parse_type(val) when is_struct(val, DateTime), do: {:ok, "'#{DateTime.to_string(val)}'"}
  defp parse_type(val) when is_struct(val, Date), do: {:ok, "'#{Date.to_string(val)}'"}
  defp parse_type(_), do: {:error, :type_not_support}
end
