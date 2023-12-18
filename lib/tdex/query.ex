defmodule Tdex.Query do
  defstruct [
    :name,
    :statement,
    :schema
  ]
end

defimpl DBConnection.Query, for: Tdex.Query do
  def decode(_query, result, _opts) do
    result
  end

  def describe(query, _opts) do
    query
  end

  def encode(_query, params, _opts) do
    params
  end

  def parse(query, _opts) do
    query
  end
end
