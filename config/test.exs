import Config

config :logger,
  backends: [:console, LoggerLagerBackend],
  handle_otp_reports: true,
  handle_sasl_reports: true,
  level: :debug

config :ssl, protocol_version: :"tlsv1.2"
