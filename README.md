# Tdex

Tdengine driver for Elixir.

Documentation: 

## Note (when use native connection)
- [Install Client Driver]("https://docs.tdengine.com/reference/connector/#Install-Client-Driver")

## Native connection
```iex
iex> {:ok, pid} = Tdex.start_link(protocol: "sql", hostname: "localhost", port: 6030, username: "root", password: "taosdata", database: "test", pool_size: 1)
{:ok, #PID<0.69.0>}

iex> Tdex.query!(pid, "SELECT ts,bid  FROM tick LIMIT 10", [])
%Tdex.Result{
  code: 0,
  req_id: 2,
  rows: [%{"bid" => 1091.752, "ts" => ~U[2015-08-09 17:00:00.000Z]}],
  affected_rows: 0,
  message: ""
}

iex> Tdex.query!(pid, "SELECT ts,bid FROM tick WHERE bid = ? AND ask = ? LIMIT 10", [1, 2])
%Tdex.Result{code: 0, req_id: 3, rows: [], affected_rows: 0, message: ""}
```
## Websocket connection
```iex
iex> {:ok, pid} = Tdex.start_link(protocol: "ws", hostname: "localhost", port: 6041, username: "root", password: "taosdata", database: "test", pool_size: 1)
{:ok, #PID<0.69.0>}

iex> Tdex.query!(pid, "SELECT ts,bid  FROM tick LIMIT 10", [])
%Tdex.Result{
  code: 0,
  req_id: 2,
  rows: [%{"bid" => 1091.752, "ts" => ~U[2015-08-09 17:00:00.000Z]}],
  affected_rows: 0,
  message: ""
}

iex> Tdex.query!(pid, "SELECT ts,bid FROM tick WHERE bid = ? AND ask = ? LIMIT 10", [1, 2])
%Tdex.Result{code: 0, req_id: 3, rows: [], affected_rows: 0, message: ""}
```

## Features

## JSON support

Tdex comes with JSON support out of the box via the [Jason](https://github.com/michalmuskala/jason) library. To use it, add :jason to your dependencies:

```elixir
{:jason, "~> 1.4"}
```
