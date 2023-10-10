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
{:ok, pid} = Tdex.start_link(hostname: "localhost", port: 6041, username: "root", password: "taosdata", database: "test")
Tdex.query(pid, "SELECT ts,bid  FROM tick LIMIT 10", [])
```

