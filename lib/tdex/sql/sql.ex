defmodule Tdex.Sql do
  alias Tdex.{Wrapper, Binary, Sql.Rows}

  def connect(opts) do
    res = GenServer.start_link(Tdex.SQL.Async, opts);
    IO.inspect{:check, res}
    res
  end

  def query(conn, statement) do
    Tdex.SQL.Async.query_async(conn, statement)
    # {:ok, res} = Wrapper.taos_query(conn, ~c(#{statement}))
    # case Wrapper.taos_errno(res) do
    #   {:ok, _} ->
    #     {:ok, field} = Wrapper.taos_fetch_fields(res)
    #     fieldNames = Binary.parse_field(field, [])
    #     Rows.read_row(res, fieldNames)
    #   {:error, errNo} ->
    #     Wrapper.taos_free_result(res)
    #     {:ok, msgErr} = Wrapper.taos_errstr(res)
    #     {:error, %Tdex.Error{code: errNo, message: msgErr}}
    # end
  end

  def stop(conn) do
    Wrapper.taos_close(conn)
    Wrapper.taos_cleanup()
  end
end
