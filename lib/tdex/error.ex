defmodule Tdex.Error do
  defexception [:code, :message, :req_id, :action]

  def exception(opts) do
    code = Keyword.get(opts, :code)
    message = Keyword.get(opts, :message)
    req_id = Keyword.get(opts, :req_id)
    action = Keyword.get(opts, :action)
    %Tdex.Error{code: code, message: message, req_id: req_id, action: action}
  end

  def message(e) do
    e.message
  end
end

defmodule Tdex.QueryError do
  defexception [:message]
end
