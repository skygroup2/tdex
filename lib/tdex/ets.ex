defmodule Tdex.Ets do
  @req_id :req_id

  def create_table(name_table) do
    case :ets.info(name_table) do
      :undefined ->
        :ets.new(name_table,
          [:public, :named_table, :ordered_set, {:read_concurrency, true}, {:write_concurrency, true}])
      _ ->
        :ok
    end
  end

  def get_req_id(name_table) do
    id = case :ets.lookup(name_table, @req_id) do
      [] ->
        :ets.insert(name_table, {@req_id, 0})
        0
      _  -> :ets.update_counter(name_table, @req_id, 1)
    end
    id
  end
end
