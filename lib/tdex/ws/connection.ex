defmodule Tdex.WS.Connection do
  import Tdex.{Ets, Binary}

  def recv_ws() do
    receive do
      { :gun_ws, _pid, _ref, {:text, data} } ->
        res = Jason.decode!(data)
        %{"code" => code, "message" => message, "action" => action, "req_id" => req_id} = res
        if code == 0 do
          {:ok, res}
        else
          {:error, %Tdex.Error{code: code, message: message, action: action, req_id: req_id}}
        end
      { :gun_ws, _pid, _ref, {:binary, data} } -> {:ok, (data)}
    after 5000 -> {:error, :timeout}
    end
  end

  @spec new_connect_ws(any, any) :: {:ok, pid()}|{:error, any()}
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
      _ ->
        {:error, %Tdex.Error{message: "ws connection failed, check host or port again"}}
    end
  catch _, ex -> {:error, ex}
  end

  def connect(pid, args) do
    action = %{
      action: "conn",
      args: %{
        req_id: get_req_id(:tdex),
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
        req_id: get_req_id(:tdex),
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
        req_id: get_req_id(:tdex),
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
        req_id: get_req_id(:tdex),
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
end
