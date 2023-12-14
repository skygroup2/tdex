defmodule Tdex.Binary do
  import Bitwise

  def parse_field(<<>>, result), do: Enum.reverse(result)
  def parse_field(fields, result) do
    <<name::binary-size(65), _::3-binary, _::4-binary, res::binary>> = fields
    v = Enum.at(:binary.split(name, <<0>>), 0)
    parse_field(res, [v|result])
  end

  def parse_block(<<_::binary-size(20), _len::32-little, rows::32-little, cols::32-little, _::binary-size(12), fields::binary-size(5*cols), blockSize::binary-size(cols*4), data::binary>>, fieldNames, precision, result) do
    {"", "", headers} =
      Enum.reduce(fieldNames, {fields, blockSize, []}, fn name, {<<type, size::32-little, rest1::binary>>, <<blockSize::32-little, rest2::binary>>, acc} ->
        {rest1, rest2, [%{type: type, size: size, block_size: blockSize, name: name}|acc]}
      end)
    bitMapSize = Bitwise.bsr(rows + 7, 3)
    {^rows, ret} =
      Enum.reverse(headers)
      |> parse_entry(rows, bitMapSize, precision, data, [])
      |> Enum.zip_reduce({0, result}, fn rows, {cnt, acc} ->
        {cnt + 1, [Enum.zip(fieldNames, rows) |> Map.new()|acc]}
      end)
    ret
  end

  @spec parse_entry(
          [%{:block_size => non_neg_integer, :type => any, optional(any) => any}],
          integer,
          integer,
          integer,
          binary,
          list
        ) :: list
  def parse_entry([], _, _, _precision, <<>>, acc), do: Enum.reverse(acc)
  def parse_entry([%{type: type, block_size: blockSize}|fields], rows, bitMapSize, precision, data, acc) when type in [8, 10, 15, 16] do
    <<offsets::binary-size(4*rows), data::binary-size(blockSize), bin::binary>> = data
    cols = parse_list1(offsets, data, type, precision, [])
    parse_entry(fields, rows, bitMapSize, precision, bin, [cols|acc])
  end
  def parse_entry([%{type: type, block_size: blockSize}|fields], rows, bitMapSize, precision, data, acc) do
    <<bitMaps::binary-size(bitMapSize), data::binary-size(blockSize), bin::binary>> = data
    cols = parse_list(bitMaps, data, type, precision, 0, [])
    parse_entry(fields, rows, bitMapSize, precision, bin, [cols|acc])
  end


  def parse_list(_, <<>>, _type, _precision, _, acc), do: Enum.reverse(acc)
  def parse_list(bitMaps, bin, type, precision, row, acc) do
    byteArrayIndex = Bitwise.bsr(row, 3)
    bitwiseOffset = 7 - Bitwise.band(row, 7)

    bitMap = if byteArrayIndex == 0 do
      <<bitMap::8-little, _::binary>> = bitMaps
      bitMap
    else
      <<_::binary-size(byteArrayIndex - 1), bitMap::8-little, _::binary>> = bitMaps
      bitMap
    end

    bitFlag = (bitMap &&& (1 <<< bitwiseOffset)) >>> bitwiseOffset
    if(bitFlag == 1) do
      {_, rest} = parse_type(type, bin, precision)
      parse_list(bitMaps, rest, type, precision, row + 1, [nil|acc])
    else
      {v, rest} = parse_type(type, bin, precision)
      parse_list(bitMaps, rest, type, precision, row + 1, [v|acc])
    end
  end

  def parse_list1(<<>>, <<>>, _type, _precision, acc), do: Enum.reverse(acc)
  def parse_list1(<<-1::32-signed, offsets::binary>>, bin, type, precision, acc), do: parse_list1(offsets, bin, type, precision, [nil|acc])
  def parse_list1(<<_::32-signed, offsets::binary>>, bin, type, precision, acc) do
    {v, rest} = parse_type(type, bin, precision)
    parse_list1(offsets, rest, type, precision, [v|acc])
  end

  def parse_type(1, <<v::8-little, rest::binary>>, _), do: {v==1, rest}
  def parse_type(2, <<v::8-little-signed, rest::binary>>, _), do: {v, rest}
  def parse_type(3, <<v::16-little-signed, rest::binary>>, _), do: {v, rest}
  def parse_type(4, <<v::32-little-signed, rest::binary>>, _), do: {v, rest}
  def parse_type(5, <<v::64-little-signed, rest::binary>>, _), do: {v, rest}
  def parse_type(6, <<v::32-float-little, rest::binary>>, _), do: {v, rest}
  def parse_type(7, <<v::64-float-little, rest::binary>>, _), do: {v, rest}
  def parse_type(8, bin, _) do
    <<len::16-little, v::binary-size(len), rest::binary>> = bin
    {v, rest}
  end
  def parse_type(9, <<v::64-little, rest::binary>>, precision) do
    ts = case precision do
      0 -> Timestamp.from_unix(v, :millisecond)
      1 -> Timestamp.from_unix(v, :microsecond)
      2 -> Timestamp.from_unix(v, :nanosecond)
    end
    {ts, rest}
  end
  def parse_type(10, bin, _) do
    <<len::16-little, v::binary-size(len), rest::binary>> = bin
    {:unicode.characters_to_binary(v, {:utf32, :little}, :utf8), rest}
  end
  def parse_type(11, <<v::8-little-unsigned, rest::binary>>, _), do: {v, rest}
  def parse_type(12, <<v::16-little-unsigned, rest::binary>>, _), do: {v, rest}
  def parse_type(13, <<v::32-little-unsigned, rest::binary>>, _), do: {v, rest}
  def parse_type(14, <<v::64-little-unsigned, rest::binary>>, _), do: {v, rest}
  def parse_type(15, bin, _) do
    <<len::16-little, v::binary-size(len), rest::binary>> = bin
    {Jason.decode!(v), rest}
  end
  def parse_type(16, bin, _) do
    <<len::16-little, v::binary-size(len), rest::binary>> = bin
    {v, rest}
  end
end
