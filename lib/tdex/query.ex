defmodule Tdex.Query do
  defstruct [
    :name,
    :statement,
    :param_oids,
    :param_formats,
    :param_types,
    :columns,
    :result_oids,
    :result_formats,
    :result_types,
    :types,
    cache: :reference
  ]
end

defimpl DBConnection.Query, for: Tdex.Query do
  def parse(%{types: nil, name: name} = query, _) do
    # for query table to match names must be equal
    %{query | name: IO.iodata_to_binary(name)}
  end

  def parse(query, _) do
    raise ArgumentError, "query #{inspect(query)} has already been prepared"
  end

  def describe(query, _), do: query

  # def encode(%{types: nil} = query, _params, _) do
  #   raise ArgumentError, "query #{inspect(query)} has not been prepared"
  # end

  def encode(query, _params, _) do
    IO.inspect("en 2")
    %{param_types: _param_types, types: _types} = query
  end

  def decode(_, res, _opts) do
    IO.puts("decode 1")
    res
  end

  # def decode(_, res, _opts) do
  #   res
  # end

  # def decode(_, copy, _opts) do
  #   copy
  # end

  ## Helpers

  defp decode_map(data, opts) do
    case opts[:decode_mapper] do
      nil -> Enum.reverse(data)
      mapper -> decode_map(data, mapper, [])
    end
  end

  defp decode_map([row | data], mapper, decoded) do
    decode_map(data, mapper, [mapper.(row) | decoded])
  end

  defp decode_map([], _, decoded) do
    IO.puts("m 2")
    decoded
  end
end
