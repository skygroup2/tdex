defmodule Tdex.Connection do
  import Tdex.Ets

  def recv_ws() do
    receive do
      { :gun_ws, _pid, _ref, {:text, data} } -> {:ok, Jason.decode!(data)}
      { :gun_ws, _pid, _ref, {:binary, data} } -> {:ok, (data)}
    after 5000 -> {:error, :timeout}
    end
  end

  def read_row(pid, dataQuery, data) do
    {:ok, dataFetch} = fetch(pid, dataQuery["id"])
    if dataFetch["completed"] do
      {:ok, List.flatten(data)}
    else
      {:ok, dateBlock} = fetch_block(pid, dataQuery["id"])
      IO.inspect(Base.encode16(dateBlock))
      result = parse_block(dateBlock, dataQuery["fields_names"])
      read_row(pid, dataQuery, [result|data])
    end
  end

  def parse_block(<<_::binary-size(20), _len::32-little, rows::32-little, cols::32-little, _::binary-size(12), fields::binary-size(5*cols), blockSize::binary-size(cols*4), data::binary>>, fieldNames) do
    {"", "", headers} =
      Enum.reduce(fieldNames, {fields, blockSize, []}, fn name, {<<type, size::32-little, rest1::binary>>, <<blockSize::32-little, rest2::binary>>, acc} ->
        {rest1, rest2, [%{type: type, size: size, block_size: blockSize, name: name}|acc]}
      end)
    bitMapSize = Bitwise.bsr(rows + 7, 3)
    IO.inspect(headers)
    parse_entry(Enum.reverse(headers), rows, bitMapSize, data, [])
      |> List.zip()
      |> Enum.map(fn x -> Enum.zip(fieldNames, Tuple.to_list(x)) end)
      |> Enum.map(fn x -> Map.new(x) end)
  end

  def parse_entry([], _, _, <<>>, acc), do: Enum.reverse(acc)
   def parse_entry([%{type: type, block_size: blockSize}|fields], rows, bitMapSize, data, acc) when type in [8, 10, 15] do
    <<offsets::binary-size(4*rows), data::binary-size(blockSize), bin::binary>> = data
    cols = parse_list1(offsets, data, type, [])
    parse_entry(fields, rows, bitMapSize, bin, [cols|acc])
  end
  # def parse_entry([%{type: type, block_size: blockSize}|fields], rows, bitMapSize, data, acc) when type in [8, 10, 15] do
  #   <<_::binary-size(4*rows), data::binary-size(blockSize), bin::binary>> = data
  #   IO.puts("check null: #{type} #{blockSize} #{inspect(data)}")
  #   cols = parse_list(data, type, [])
  #   parse_entry(fields, rows, bitMapSize, bin, [cols|acc])
  # end
  @spec parse_entry(
          [%{:block_size => non_neg_integer, :type => any, optional(any) => any}],
          integer,
          any,
          binary,
          any
        ) :: list
  def parse_entry([%{type: type, block_size: blockSize}|fields], rows, bitMapSize, data, acc) do
    <<_::binary-size(bitMapSize), data::binary-size(blockSize), bin::binary>> = data
    cols = parse_list(data, type, [])
    parse_entry(fields, rows, bitMapSize, bin, [cols|acc])
  end

  def parse_list(<<>>, _type, acc), do: Enum.reverse(acc)
  def parse_list(bin, type, acc) do
    {v, rest} = parse_type(type, bin)
    parse_list(rest, type, [v|acc])
  end

  def parse_list1(<<>>, <<>>, _type, acc), do: Enum.reverse(acc)
  def parse_list1(offsets, bin, type, acc) do
    <<offset::32-signed, offsets1::binary>> = offsets
    if offset == -1 do
      parse_list1(offsets1, bin, type, [nil|acc])
    else
      {v, rest} = parse_type(type, bin)
      parse_list(rest, type, [v|acc])
    end
  end

  def parse_type(1, <<v::8-little, rest::binary>>), do: {v==1, rest}
  def parse_type(2, <<v::8-little, rest::binary>>), do: {v, rest}
  def parse_type(3, <<v::16-little, rest::binary>>), do: {v, rest}
  def parse_type(4, <<v::32-little, rest::binary>>), do: {v, rest}
  def parse_type(5, <<v::64-little, rest::binary>>), do: {v, rest}
  def parse_type(6, <<v::64-float-little, rest::binary>>), do: {v, rest}
  def parse_type(7, <<v::64-float-little, rest::binary>>), do: {v, rest}
  def parse_type(8, bin) do
    <<len::16-little, v::binary-size(len), rest::binary>> = bin
    {v, rest}
  end
  def parse_type(9, <<v::64-little, rest::binary>>), do: {DateTime.from_unix!(v, :millisecond), rest}
  def parse_type(10, bin) do
    <<len::16-little, v::binary-size(len), rest::binary>> = bin
    {:unicode.characters_to_binary(v, {:utf32, :little}, :utf8), rest}
  end
  def parse_type(11, <<v::8-unsigned-little, rest::binary>>), do: {v, rest}
  def parse_type(12, <<v::16-unsigned-little, rest::binary>>), do: {v, rest}
  def parse_type(13, <<v::32-unsigned-little, rest::binary>>), do: {v, rest}
  def parse_type(14, <<v::64-unsigned-little, rest::binary>>), do: {v, rest}
  def parse_type(15, bin) do
    <<len::16-little, v::binary-size(len), rest::binary>> = bin
    {Jason.decode!(v), rest}
  end

  def new_connect_ws(host, port) do
    url = "ws://#{host}:#{port}/rest/ws"
    headers = %{
      "accept-language" => "en-US,en;q=0.9",
      "accept-encoding" => "gzip, deflate, br",
    }
    proxy_opts = ws_default_option(25_000)
    case Gun.ws_upgrade(url, headers, proxy_opts) do
      %{status_code: 101, protocols: ["websocket"]} = resp ->
        {:ok, resp[:pid]}
      exp ->
        exp
    end
  end

  def connect(pid, args) do
    action = %{
      action: "conn",
      args: %{
        reqID: get_req_id(:tdex),
        user: args[:username],
        password: args[:password],
        db: args[:database]
      }
    }

    Gun.ws_send(pid, {:text, Jason.encode!(action)})
    recv_ws()
  end

  def query(pid, statement) do
    action = %{
      action: "query",
      args: %{
        reqID: get_req_id(:tdex),
        sql: statement
      }
    }

    Gun.ws_send(pid, {:text, Jason.encode!(action)})
    recv_ws()
  end

  def fetch(pid, id) do
    action = %{
      action: "fetch",
      args: %{
        reqID: get_req_id(:tdex),
        id: id
      }
    }

    Gun.ws_send(pid, {:text, Jason.encode!(action)})
    recv_ws()
  end

  def fetch_block(pid, id) do
    action = %{
      action: "fetch_block",
      args: %{
        reqID: get_req_id(:tdex),
        id: id
      }
    }

    Gun.ws_send(pid, {:text, Jason.encode!(action)})
    recv_ws()
  end

  def ws_default_option(connect_timeout, recv_timeout\\ 30000) do
    default_option(connect_timeout, recv_timeout) |> Map.merge(%{protocols: [:http], is_ws: true})
  end

  def default_option(connect_timeout, recv_timeout\\ 30000) do
    %{
      connect_timeout: connect_timeout,
      recv_timeout: recv_timeout,
      tcp_opts: [{:reuseaddr, true}, {:linger, {false, 0}}],
      tls_opts: [{:reuse_sessions, false}, {:verify, :verify_none}, {:logging_level, :error}, {:log_alert, false}],
      http_opts: %{
        version: :"HTTP/1.1"
      },
      http2_opts: %{
        settings_timeout: 15000,
        preface_timeout: 30000
      },
      ws_opts: %{
        compress: true,
      },
    }
  end

  def exec(pid, payload) do
    Gun.ws_send(pid, payload)
  end
end
