ExUnit.start()
defmodule TSQL do

  def cmd(args, database \\ "") do
    args = ["-h", "localhost"] ++ args

    args = if database != "" do
      args ++ ["-d", "tdex_test"]
    else
      args
    end

    {output, status} = System.cmd("taos", args, stderr_to_stdout: true)

    if status != 0 do
      IO.puts("""
      Command:

      taos #{Enum.join(args, " ")}

      error'd with:

      #{output}

      Please verify the user "root" exists, and it has permissions to
      create databases and users.
      """)

      System.halt(1)
    end
    output
  end

end

TSQL.cmd(["-s", "CREATE DATABASE IF NOT EXISTS tdex_test"])

sql_test = """
DROP TABLE IF EXISTS table_int;
CREATE TABLE table_int (ts TIMESTAMP, num INT);

DROP TABLE IF EXISTS table_int_unsigned;
CREATE TABLE table_int_unsigned (ts TIMESTAMP, num INT UNSIGNED);

DROP TYPE IF EXISTS table_bigint;
CREATE TABLE table_bigint (ts TIMESTAMP, num BIGINT);

DROP TYPE IF EXISTS table_bigint_unsigned;
CREATE TABLE table_bigint_unsigned (ts TIMESTAMP, num BIGINT UNSIGNED);

DROP TYPE IF EXISTS table_float;
CREATE TABLE table_float (ts TIMESTAMP, num FLOAT);

DROP TYPE IF EXISTS table_double;
CREATE TABLE table_double (ts TIMESTAMP, num DOUBLE);

DROP TYPE IF EXISTS table_binary;
CREATE TABLE table_binary (ts TIMESTAMP, num BINARY);

DROP TYPE IF EXISTS table_smallint;
CREATE TABLE table_smallint (ts TIMESTAMP, num SMALLINT);

DROP TYPE IF EXISTS table_smallint_unsigned;
CREATE TABLE table_smallint_unsigned (ts TIMESTAMP, num SMALLINT UNSIGNED	);

DROP TYPE IF EXISTS table_tinyint;
CREATE TABLE table_tinyint (ts TIMESTAMP, num TINYINT);

DROP TYPE IF EXISTS table_tinyint_unsigned;
CREATE TABLE table_tinyint_unsigned (ts TIMESTAMP, num TINYINT UNSIGNED	);

DROP TYPE IF EXISTS table_bool;
CREATE TABLE table_bool (ts TIMESTAMP, isLock BOOL);

DROP TYPE IF EXISTS table_nchar;
CREATE TABLE table_nchar (ts TIMESTAMP, str NCHAR(265));

DROP TYPE IF EXISTS table_varchar;
CREATE TABLE table_varchar (ts TIMESTAMP, str VARCHAR(265));
"""

TSQL.cmd(["-s", sql_test], "tdex_test")

sql_insert_data = """
INSERT INTO table_int VALUES("2023-10-18", -1);

INSERT INTO table_int_unsigned VALUES("2023-10-18", 1);

INSERT INTO table_bigint VALUES("2023-10-18", -9223372036854775800);

INSERT INTO table_bigint_unsigned VALUES("2023-10-18", 9223372036854775800);

INSERT INTO table_float VALUES("2023-10-18", 1.29);

INSERT INTO table_double VALUES("2023-10-18", 1.23456789012345678);

INSERT INTO table_smallint VALUES("2023-10-18", -10);

INSERT INTO table_smallint_unsigned VALUES("2023-10-18", 10);

INSERT INTO table_bool VALUES("2023-10-18", true);

INSERT INTO table_nchar VALUES("2023-10-18", "hoang");

INSERT INTO table_varchar VALUES("2023-10-18", "hoang");
"""

TSQL.cmd(["-s", sql_insert_data], "tdex_test")

defmodule TDex.TestHelper do
  defmacro query(stat, params, opts \\ []) do
    quote do
      case TDex.query(var!(context)[:pid], unquote(stat), unquote(params), unquote(opts)) do
        {:ok, %TDex.Query{}, %TDex.Result{rows: []}} -> :ok
        {:ok, %TDex.Query{}, %TDex.Result{rows: rows}} -> rows
        {:error, err} -> err
      end
    end
  end

  defmacro query!(stat, params, opts \\ []) do
    quote do
      TDex.query!(var!(context)[:pid], unquote(stat), unquote(params), unquote(opts))
    end
  end

  defmacro execute(query, params, opts \\ []) do
    quote do
      case TDex.execute(var!(context)[:pid], unquote(query), unquote(params), unquote(opts)) do
        {:ok, %TDex.Query{}, %TDex.Result{rows: []}} -> :ok
        {:ok, %TDex.Query{}, %TDex.Result{rows: rows}} -> rows
        {:error, err} -> err
      end
    end
  end
end
