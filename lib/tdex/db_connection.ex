defmodule Tdex.DBConnection do
  use DBConnection
  alias Tdex.Common
  require Logger
  require Skn.Log

  @impl true
  def connect(opts) do
    opts = Map.new(opts)
    case opts.protocol.connect(opts) do
      {:ok, pid} -> {:ok, %{opts | conn: pid}}
      {:error, _} = error -> error
    end
  end

  @impl true
  def checkout(state) do
    {:ok, state}
  end

  @impl true
  def handle_rollback(_opts, state) do
    {:ok, nil, state}
  end

  @impl true
  def handle_begin(_opts, state) do
    {:ok, nil, state}
  end

  @impl true
  def handle_fetch(_query, _cursor, _opts, state) do
    {:cont, nil, state}
  end

  @impl true
  def handle_declare(query, _params, _opts, state) do
    {:ok, query, nil, state}
  end

  @impl true
  def handle_commit(_opts, state) do
    {:ok, nil, state}
  end

  @impl true
  def ping(state) do
    {:ok, state}
  end

  @impl true
  def disconnect(_, state) do
    state.protocol.stop(state.conn)
    :ok
  end

  @impl true
  def handle_status(_opts, state) do
    {:idle, state}
  end

  @impl true
  def handle_prepare(query, _opts, state) do
    {:ok, query, state}
  end

  @impl true
  def handle_execute(query, params, _, %{conn: conn, protocol: protocol} = state) do
    case query do
      %{schema: nil, statement: sql} ->
        with {:ok, query_params} <- Common.interpolate_params(sql, params),
          {:ok, result} <- protocol.query(conn, query_params)
        do
          {:ok, %Tdex.Query{name: "", statement: query_params}, result, state}
        else
          {:error, error} -> {:error, error, state}
        end
      %{schema: sche, statement: sql} ->
        {:ok, stmt} = protocol.statement_init(conn, sql)
        try do
          Enum.each(params, fn row ->
            Enum.each(row, fn {k, v} ->
              case sche[k] do
                {:ts, idx} -> :ok = protocol.bind_set_timestamp(stmt, idx, v)
                {:bool, idx} -> :ok = protocol.bind_set_bool(stmt, idx, v)
                {:int32, idx} -> :ok = protocol.bind_set_int32(stmt, idx, v)
                {:int16, idx} -> :ok = protocol.bind_set_int16(stmt, idx, v)
                {:int8, idx} -> :ok = protocol.bind_set_int8(stmt, idx, v)
                {:int64, idx} -> :ok = protocol.bind_set_int64(stmt, idx, v)
                {:float, idx} -> :ok = protocol.bind_set_float(stmt, idx, v)
                {:double, idx} -> :ok = protocol.bind_set_double(stmt, idx, v)
                {:varbinary, idx} -> :ok = protocol.bind_set_varbinary(stmt, idx, v)
                {:varchar, idx} -> :ok = protocol.bind_set_varchar(stmt, idx, v)
              end
            end)
            :ok = protocol.bind_param(stmt)
          end)
          result = protocol.execute_statement(stmt)
          {:ok, query, result, state}
        catch _, ex ->
          {:error, ex, state}
        after
          protocol.close_statement(stmt)
        end
    end
  catch _, ex ->
    {:error, ex, state}
  end

  @impl true
  def handle_deallocate(_query, _cursor, _opts, state) do
    {:ok, nil, state}
  end

  @impl true
  def handle_close(_query, _opts, state) do
    disconnect(nil, state)
    {:ok, nil, state}
  end
end
