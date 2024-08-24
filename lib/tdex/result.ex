defmodule TDex.Result do
  defstruct [:code, :req_id, :rows, affected_rows: 0, message: nil]
end
