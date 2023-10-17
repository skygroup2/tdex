defmodule Tdex.Sql do
  alias Tdex.{Wrapper, Binary, Sql.Rows}

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
    case Wrapper.taos_errno(res) do
      {:ok, _} ->
        {:ok, field} = Wrapper.taos_fetch_fields(res)
        fieldNames = Binary.parse_field(field, [])
        Rows.read_row(res, fieldNames, [])
      _ ->
        {:ok, error} = Wrapper.taos_errstr(res)
        {:error, error}
    end
  end

  def disconnect(_) do

  end
end
