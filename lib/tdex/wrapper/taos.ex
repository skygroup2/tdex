defmodule Tdex.Wrapper do
  @compile {:autoload, false}
  @on_load {:load_nifs, 0}

  def load_nifs do
    path = :filename.join(:code.priv_dir(:tdex), ~C"lib_taos_nif")
    :erlang.load_nif(path, 0)
  end

  def taos_connect(_ip, _user, _pass, _db, _port) do
    raise "taos_connect not implemented"
  end

  def taos_cleanup() do
    raise "taos_cleanup not implemented"
  end

  def taos_select_db(_connect, _db) do
    raise "taos_select_db not implemented"
  end

  def taos_fetch_fields(_res) do
    raise "taos_fetch_fields not implemented"
  end

  def taos_field_count(_res) do
    raise "taos_field_count not implemented"
  end

  def taos_result_precision(_res) do
    raise "taos_result_precision not implemented"
  end

  def taos_affected_rows(_res) do
    raise "taos_affected_rows not implemented"
  end

  def taos_print_row(_row, _field, _num_fields) do
    raise "taos_print_row not implemented"
  end

  def taos_fetch_raw_block(_res) do
    raise "taos_fetch_raw_block not implemented"
  end

  def taos_free_result(_res) do
    raise "taos_free_result not implemented"
  end

  def taos_query(_connect, _sql) do
    raise "taos_query_a not implemented"
  end

  def taos_errstr(_res) do
    raise "taos_errno not implemented"
  end

  def taos_errno(_res) do
    raise "taos_errstr not implemented"
  end

  def taos_fetch_row(_res) do
    raise "taos_fetch_row not implemented"
  end

  def taos_query_a(_connect, _sql, _callback, _params) do
    raise "taos_query_a not implemented"
  end

  def taos_close(_connect) do
    raise "taos_close not implemented"
  end

  def taos_kill_query(_connect) do
    raise "taos_kill_query not implemented"
  end

  def taos_stmt_init(_taos, _param_cnt) do
    raise "nif load fail"
  end
  def taos_stmt_close(_stmt) do
    raise "nif load fail"
  end
  def taos_stmt_bind_param_batch(_stmt) do
    raise "nif load fail"
  end
  def taos_stmt_execute(_stmt) do
    raise "nif load fail"
  end
  def taos_multi_bind_set_timestamp(_stmt, _index, _ts) do
    raise "nif load fail"
  end
  def taos_multi_bind_set_byte(_stmt, _index, _value) do
    raise "nif load fail"
  end
  def taos_multi_bind_set_int(_stmt, _index, _value) do
    raise "nif load fail"
  end
  def taos_multi_bind_set_long(_stmt, _index, _value) do
    raise "nif load fail"
  end
  def taos_multi_bind_set_short(_stmt, _index, _value) do
    raise "nif load fail"
  end
  def taos_multi_bind_set_bool(_stmt, _index, _value) do
    raise "nif load fail"
  end
  def taos_multi_bind_set_float(_stmt, _index, _value) do
    raise "nif load fail"
  end
  def taos_multi_bind_set_double(_stmt, _index, _value) do
    raise "nif load fail"
  end
  def taos_multi_bind_set_varbinary(_stmt, _index, _value) do
    raise "nif load fail"
  end
  def taos_multi_bind_set_varchar(_stmt, _index, _value) do
    raise "nif load fail"
  end
end
