# Tdex

TDengine elixir driver

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `tdex` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:tdex, "~> 0.1.0"}
  ]
end
```

```elixir
c("taos.ex")
{ ok, connect } = Wrapper.Taos.taos_connect('localhost', 'root', 'taosdata', 'test', 6030)

Wrapper.Taos.taos_select_db(connect, 'test')

{ ok, res } = Wrapper.Taos.taos_query(connect, 'SELECT * FROM tick LIMIT 10')

Wrapper.Taos.taos_errstr(res)
Wrapper.Taos.taos_errno(res)

{ok ,num_fields} = Wrapper.Taos.taos_field_count(res)

{ok ,field} = Wrapper.Taos.taos_fetch_fields(res)
{ok, row} = Wrapper.Taos.taos_fetch_row(res)

Wrapper.Taos.taos_print_row('', row, field, num_fields)
Wrapper.Taos.taos_close(connect)
```

