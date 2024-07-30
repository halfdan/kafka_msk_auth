import Config

config :kafka_msk_auth,
  region: "us-east-1"

import_config "#{Mix.env()}.exs"
