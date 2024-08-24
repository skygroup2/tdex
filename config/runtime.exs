import Config

if config_env() == :prod do
  config :tdex, :logger, [
    {:handler, :tdex_log, :logger_std_h, %{
      config: %{
        file: to_charlist("#{System.fetch_env!("LOG_DIR")}/#{System.fetch_env!("RELEASE_NODE")}.log"),
        max_no_files: 10,
        max_no_bytes: 50 * 1024 * 1024,
      },
      filter_default: :log,
      filters: [
        {:sasl_domain, {&:logger_filters.domain/2, {:stop, :equal, [:otp, :sasl]}}}
      ],
      formatter: {:logger_formatter, %{time_offset: ~c"Z", chars_limit: 1800, max_size: 2000, depth: 10, template: [:time, " ", :level, " ", :mfa, "_", :line, " ", :pid, " ", :msg, "\n"]}},
      level: :debug
    }},
    {:handler, :tdex_log_sasl, :logger_std_h, %{
      config: %{
        file: to_charlist("#{System.fetch_env!("LOG_DIR")}/#{System.fetch_env!("RELEASE_NODE")}_sasl.log"),
        max_no_files: 10,
        max_no_bytes: 20 * 1024 * 1024,
      },
      filter_default: :stop,
      filters: [
        {:remote_gl, {&:logger_filters.remote_gl/2, :stop}},
        {:sasl_domain, {&:logger_filters.domain/2, {:log, :equal, [:otp, :sasl]}}}
      ],
      formatter: {:logger_formatter, %{time_offset: ~c"Z", chars_limit: 1800, max_size: 2000, depth: 10, legacy_header: true, single_line: false}},
      level: :notice
    }},
    {:handler, :tdex_console, :logger_std_h, %{
      config: %{
        type: :standard_io,
        burst_limit_enable: true,
        drop_mode_qlen: 200,
        flush_qlen: 1000,
        sync_mode_qlen: 10,
        overload_kill_restart_after: 5000,
        burst_limit_max_count: 500,
        burst_limit_window_time: 1000,
        overload_kill_enable: false,
        overload_kill_mem_size: 3000000,
        overload_kill_qlen: 20000,
        filesync_repeat_interval: :no_repeat
      },
      filter_default: :log,
      filters: [
        {:sasl_domain, {&:logger_filters.domain/2, {:stop, :equal, [:otp, :sasl]}}}
      ],
      formatter: Logger.Formatter.new(utc_log: true),
      level: :debug
    }}
  ]

  config :logger,
    backends: [{LoggerFileBackend, :debug_log}],
    handle_sasl_reports: true,
    level: :debug
end
