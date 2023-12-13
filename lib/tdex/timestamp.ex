defmodule Timestamp do
	defstruct year: 1970, month: 1, day: 1, hour: 0, minute: 0, second: 0, nanosecond: 0

	def to_datetime_base_second(%{year: y, month: mon, day: day, hour: h, minute: min, second: s}) do
		%DateTime{year: y, month: mon, day: day, hour: h, minute: min, second: s, time_zone: "Etc/UTC", zone_abbr: "UTC", utc_offset: 0, std_offset: 0}
	end

	def from_unix(ts, unit\\:nanosecond)
	def from_unix(ts, :second) do
		d = DateTime.from_unix!(ts, :second) |> Map.from_struct()
		struct(%Timestamp{}, d)
	end
	def from_unix(ts, :millisecond) do
		millisecond = rem(ts, 1_000)
		%{from_unix(div(ts, 1_000), :second)| nanosecond: millisecond * 1_000_000}
	end
	def from_unix(ts, :microsecond) do
		microsecond = rem(ts, 1_000_000)
		%{from_unix(div(ts, 1_000_000), :second)| nanosecond: microsecond * 1_000}
	end
	def from_unix(ts, :nanosecond) do
		nanosecond = rem(ts, 1_000_000_000)
		%{from_unix(div(ts, 1_000_000_000), :second)| nanosecond: nanosecond}
	end

	def to_unix(ts, unit\\:nanosecond)
	def to_unix(ts, _unit) when not is_struct(ts, Timestamp), do: throw :invalid_timestamp
	def to_unix(ts, :second) do
		to_datetime_base_second(ts) |> DateTime.to_unix(:second)
	end
	def to_unix(ts, :millisecond) do
		to_unix(ts, :second) * 1000 + div(ts.nanosecond, 1_000_000)
	end
	def to_unix(ts, :microsecond) do
		to_unix(ts, :second) * 1_000_000 + div(ts.nanosecond, 1_000)
	end
	def to_unix(ts, :nanosecond) do
		to_unix(ts, :second) * 1_000_000_000 + ts.nanosecond
	end
	
	def utc_now() do
		from_unix(System.system_time(:nanosecond), :nanosecond)
	end

	def add(ts, amount, unit\\:nanosecond)
	def add(ts, amount, :nanosecond) do
		from_unix(to_unix(ts, :nanosecond) + amount, :nanosecond)
	end
	def add(ts, amount, :microsecond) do
		from_unix(to_unix(ts, :nanosecond) + amount * 1_000, :nanosecond)
	end
	def add(ts, amount, :millisecond) do
		from_unix(to_unix(ts, :nanosecond) + amount * 1_000_000, :nanosecond)
	end
	def add(ts, amount, :hour) do
		from_unix(to_unix(ts, :nanosecond) + amount * 3600_000_000_000, :nanosecond)
	end
	def add(ts, amount, :minute) do
		from_unix(to_unix(ts, :nanosecond) + amount * 60_000_000_000, :nanosecond)
	end
	def add(ts, amount, :second) do
		from_unix(to_unix(ts, :nanosecond) + amount * 1_000_000_000, :nanosecond)
	end
	def add(ts, amount, :day) do
		from_unix(to_unix(ts, :nanosecond) + amount * 86400_000_000_000, :nanosecond)
	end

	def after?(ts1, ts2), do: to_unix(ts1) > to_unix(ts2)
	def before?(ts1, ts2), do: to_unix(ts1) < to_unix(ts2)
	def compare(ts1, ts2) do
		ts1 = to_unix(ts1)
		ts2 = to_unix(ts2)
		cond do
			ts1 == ts2 -> :eq
			ts1 > ts2 -> :gt
			true -> :lt
		end
	end

	def diff(ts1, ts2, unit\\:nanosecond)
	def diff(ts1, ts2, :nanosecond), do: to_unix(ts1) - to_unix(ts2)
	def diff(ts1, ts2, :microsecond), do: to_unix(ts1, :microsecond) - to_unix(ts2, :microsecond)
	def diff(ts1, ts2, :millisecond), do: to_unix(ts1, :millisecond) - to_unix(ts2, :millisecond)
	def diff(ts1, ts2, unit) do
		DateTime.diff(to_datetime_base_second(ts1), to_datetime_base_second(ts2), unit)
	end

	def to_string(%{year: year, month: mon, day: day, hour: h, minute: min, second: s, nanosecond: ns}) do
		:io_lib.format("~4..0B-~2..0B-~2..0B ~2..0B:~2..0B:~2..0B.#{Integer.to_string(ns) |> String.pad_leading(3, "0")}Z", [year, mon, day, h, min, s]) |> :erlang.list_to_binary
	end

	def sigil_TS(ts, []) do
		[year, mon, day, hour, min, second, nano] = Regex.split(~r/[\s-:\.]/, ts)
		{nano, "Z"} = Float.parse("0.#{nano}")
		d = %DateTime{
			year: String.to_integer(year),
			month: String.to_integer(mon),
			day: String.to_integer(day),
			hour: String.to_integer(hour),
			minute: String.to_integer(min),
			second: String.to_integer(second), 
			time_zone: "Etc/UTC", zone_abbr: "UTC", utc_offset: 0, std_offset: 0
		}
		%{struct(%Timestamp{}, Map.from_struct(d))| nanosecond: round(nano * 1_000_000_000)}
	end

	defmacro __using__(_opts) do
    quote do
			import Timestamp, only: [sigil_TS: 2]
		end
  end

	defimpl Inspect do
		def inspect(%{year: y, month: mon, day: day, hour: h, minute: min, second: s, nanosecond: ns}, _opts) do
			dtFormat = :io_lib.format("~4..0B-~2..0B-~2..0B ~2..0B:~2..0B:~2..0B", [y, mon, day, h, min, s]) |> :erlang.list_to_binary()
			nanoFormat = Integer.to_string(ns) |> String.pad_leading(3, "0")
			Inspect.Algebra.concat(["~TS[", dtFormat, ".", nanoFormat, "Z]"])
		end
	end
end