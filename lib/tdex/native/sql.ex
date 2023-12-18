defmodule Tdex.Native do
  alias Tdex.{Wrapper, Binary, Native.Rows}

  def connect(opts) do
    hostname = ~c(#{opts.hostname})
    username = ~c(#{opts.username})
    password = ~c(#{opts.password})
    database = ~c(#{opts.database})
    port = opts.port
    Wrapper.taos_connect(hostname, username, password, database, port)
  end

  def query(conn, statement) do
    {:ok, res} = Wrapper.taos_query(conn, :erlang.binary_to_list(statement))
    with {:ok, _} <- Wrapper.taos_errno(res),
         {:ok, fields} <- Wrapper.taos_fetch_fields(res),
         {:ok, precision} <- Wrapper.taos_result_precision(res)
    do
      fieldNames = Binary.parse_field(fields, [])
      Rows.read_row(res, fieldNames, precision, [])
    else
      {:error, _} ->
        Wrapper.taos_free_result(res)
        {:ok, msgErr} = Wrapper.taos_errstr(res)
        {:error, %Tdex.Error{message: msgErr}}
    end
  end

  def test() do
    [{:undefined, p, :supervisor, [DBConnection.ConnectionPool.Pool]}] = Process.whereis(DBConnection.ConnectionPool.Supervisor) |> Supervisor.which_children()
    [{{Tdex.DBConnection, _, _}, p1, :worker, [DBConnection.Connection]}|_] = Supervisor.which_children(p)
    {:no_state, %{state: %{conn: conn}}} = :sys.get_state(p1)
    tsNow = System.system_time(:nanosecond)
    sql = 'insert into table_varbinary values(?, ?)'
    {:ok, stmt} = Wrapper.taos_stmt_init(conn, sql)
    try do
      :ok = Wrapper.taos_multi_bind_set_timestamp(stmt, 0, tsNow)
      :ok = Wrapper.taos_multi_bind_set_varbinary(stmt, 1, "Hello tdengine")
      :ok = Wrapper.taos_stmt_bind_param_batch(stmt)
      Wrapper.taos_stmt_execute(stmt)
    catch _, ex ->
      IO.inspect(ex);
      IO.inspect(__STACKTRACE__)
    after
      Wrapper.taos_stmt_close(stmt)
    end
  end

  def stop(conn) do
    Wrapper.taos_close(conn)
    Wrapper.taos_cleanup()
  end
end
