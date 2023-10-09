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
    :ets.update_counter(name_table, @req_id, {2, 1}, {@req_id, 0})
  end
end
