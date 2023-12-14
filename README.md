# Tdex

Tdengine driver for Elixir.

Documentation: 

## Note (when use native connection)
- [Install Client Driver](https://docs.tdengine.com/reference/connector/#Install-Client-Driver)

## Examples

### 1. Connect Tdengine
#### 1.1. Use params
```iex
iex> {:ok, pid} = Tdex.start_link(protocol: "native", hostname: "localhost", port: 6030, username: "root", password: "taosdata", database: "test", pool_size: 1)

OR

iex> {:ok, pid} = Tdex.start_link(protocol: "ws", hostname: "localhost", port: 6041, username: "root", password: "taosdata", database: "test", pool_size: 1, timeout: 120_000)
```

#### 1.2. Use file config
Where the configuration for the Repo must be in your application environment, usually defined in your config/config.exs
```elixir
# native connect
config :tdex, Tdex.Repo,
  protocol: "native",
  username: "root",
  database: "test",
  hostname: "127.0.0.1",
  password: "taosdata",
  port: 6030,
  pool_size: 16

# ws connect
config :tdex, Tdex.Repo,
  protocol: "ws",
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