defmodule TDex.Sql do
  alias TDex.{Wrapper, Binary, Sql.Rows}

  def connect(opts) do
    hostname = ~c(#{opts.hostname})
    username = ~c(#{opts.username})
    password = ~c(#{opts.password})
    database = ~c(#{opts.database})
    port = opts.port
    Wrapper.taos_connect(hostname, username, password, database, port)
  end

  def query(conn, statement) do
    {:ok, res} = Wrapper.taos_query(conn, ~c(#{statement}))
    with {:ok, _} <- Wrapper.taos_errno(res),
         {:ok, fields} <- Wrapper.taos_fetch_fields(res)
    do
      fieldNames = Binary.parse_field(fields, [])
      Rows.read_row(res, fieldNames)
    else
      {:error, _} ->
        Wrapper.taos_free_result(res)
        {:ok, msgErr} = Wrapper.taos_errstr(res)
        {:error, %TDex.Error{message: msgErr}}
    end
  end

  def stop(conn) do
    Wrapper.taos_close(conn)
    Wrapper.taos_cleanup()
  end
end
