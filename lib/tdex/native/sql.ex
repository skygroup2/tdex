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
    try do
      {:ok, 0} = Wrapper.taos_errno(res)
      {:ok, fields} = Wrapper.taos_fetch_fields(res)
      {:ok, precision} = Wrapper.taos_result_precision(res)
      fieldNames = Binary.parse_field(fields, [])
      Rows.read_row(res, fieldNames, precision, [])
    catch _, _ex ->
      {:ok, msgErr} = Wrapper.taos_errstr(res)
      {:error, %Tdex.Error{message: msgErr}}
    after
      Wrapper.taos_free_result(res)
    end
  end

  def statement_init(conn, sql) do
    Wrapper.taos_stmt_init(conn, sql)
  end

  def bind_set_timestamp(stmt, index, ts) do
    Wrapper.taos_multi_bind_set_timestamp(stmt, index, ts)
  end

  def bind_set_bool(stmt, index, true), do: Wrapper.taos_multi_bind_set_bool(stmt, index, 1)
  def bind_set_bool(stmt, index, false), do: Wrapper.taos_multi_bind_set_bool(stmt, index, 0)

  def bind_set_int8(stmt, index, v) do
    Wrapper.taos_multi_bind_set_byte(stmt, index, v)
  end

  def bind_set_int16(stmt, index, v) do
    Wrapper.taos_multi_bind_set_short(stmt, index, v)
  end

  def bind_set_int32(stmt, index, v) do
    Wrapper.taos_multi_bind_set_int(stmt, index, v)
  end

  def bind_set_int64(stmt, index, v) do
    Wrapper.taos_multi_bind_set_long(stmt, index, v)
  end
  def bind_set_float(stmt, index, v) do
    Wrapper.taos_multi_bind_set_float(stmt, index, v)
  end
  def bind_set_double(stmt, index, v) do
    Wrapper.taos_multi_bind_set_double(stmt, index, v)
  end
  def bind_set_varbinary(stmt, index, v) do
    Wrapper.taos_multi_bind_set_varbinary(stmt, index, v)
  end
  def bind_set_varchar(stmt, index, v) do
    Wrapper.taos_multi_bind_set_varchar(stmt, index, v)
  end

  def bind_param(stmt) do
    Wrapper.taos_stmt_bind_param_batch(stmt)
  end
  
  def execute_statement(stmt) do
    Wrapper.taos_stmt_execute(stmt)
  end

  def close_statement(stmt) do
    Wrapper.taos_stmt_close(stmt)
  end

  def test() do
    [{:undefined, p, :supervisor, [DBConnection.ConnectionPool.Pool]}] = Process.whereis(DBConnection.ConnectionPool.Supervisor) |> Supervisor.which_children()
    [{{Tdex.DBConnection, _, _}, p1, :worker, [DBConnection.Connection]}|_] = Supervisor.which_children(p)
    {:no_state, %{state: %{conn: conn}}} = :sys.get_state(p1)
    tsNow = System.system_time(:nanosecond)
    sql = 'insert into table_varchar values(?, ?)'
    # sql = 'select * from table_varbinary where ts < ?'
    {:ok, stmt} = Wrapper.taos_stmt_init(conn, sql)
    try do
      :ok = Wrapper.taos_multi_bind_set_timestamp(stmt, 0, tsNow)
      :ok = Wrapper.taos_multi_bind_set_varchar(stmt, 1, "AXUUSD")
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
