# Tdex

Tdengine driver for Elixir.

Documentation: 

## Note (when use native connection)
- [Install Client Driver](https://docs.tdengine.com/reference/connector/#Install-Client-Driver)

## Examples

### 1. Connect Tdengine
#### 1.1. Use params
```iex
iex> {:ok, pid} = Tdex.start_link(protocol: :native, hostname: "localhost", port: 6030, username: "root", password: "taosdata", database: "test", pool_size: 1)

OR

iex> {:ok, pid} = Tdex.start_link(protocol: :ws, hostname: "localhost", port: 6041, username: "root", password: "taosdata", database: "test", pool_size: 1, timeout: 120_000)
```

#### 1.2. Use file config
Where the configuration for the Repo must be in your application environment, usually defined in your config/config.exs
```elixir
# native connect
config :tdex, Tdex.Repo,
  protocol: :native,
  username: "root",
  database: "test",
  hostname: "127.0.0.1",
  password: "taosdata",
  port: 6030,
  pool_size: 16

# ws connect
config :tdex, Tdex.Repo,
  protocol: :ws,
  username: "root",
  database: "cfd80",
  hostname: "127.0.0.1",
  password: "taosdata",
  port: 6041,
  timeout: 1000,
  pool_size: 16
```

After configuration is complete, run the command:

```iex
iex> {:ok, pid} = Tdex.start_link()
```

### 2. Query
```iex
iex> Tdex.query!(pid, "SELECT ts,bid FROM tick LIMIT 10", [])
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

# Parameter binding example
CREATE TABLE table_varbinary (ts TIMESTAMP, val VARBINARY);
```
    tsNow = System.system_time(:nanosecond)
    sql = 'insert into table_varbinary values(?, ?)'
    {:ok, stmt} = Wrapper.taos_stmt_init(conn, sql)
    try do
      :ok = Wrapper.taos_multi_bind_set_timestamp(stmt, 0, tsNow)
      :ok = Wrapper.taos_multi_bind_set_varbinary(stmt, 1, "Hello tdengine")
      :ok = Wrapper.taos_stmt_bind_param_batch(stmt)
      Wrapper.taos_stmt_execute(stmt)
    catch _, ex ->
      IO.inspect(ex);
      IO.inspect(__STACKTRACE__)
    after
      IO.puts("close stmt")
      Wrapper.taos_stmt_close(stmt)
    end
```
## Features

## JSON support

Tdex comes with JSON support out of the box via the [Jason](https://github.com/michalmuskala/jason) library. To use it, add :jason to your dependencies:

```elixir
{:jason, "~> 1.4"}
```

# Install
```elixir
{:tdex, git: "git@github.com:skygroup2/tdex.git", branch: "dev"},
```