defmodule KafkaMskAuth.MixProject do
  use Mix.Project

  @url "https://github.com/halfdan/kafka_msk_auth"
  @version "0.1.0"

  def project do
    [
      app: :kafka_msk_auth,
      version: @version,
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      package: package(),
      deps: deps(),
      docs: docs()
    ]
  end

  defp package do
    [
      description: "Kafka Auth library for AWS MSK",
      files: ["lib", "config", "mix.exs", "README*"],
      maintainers: ["Fabian Becker"],
      licenses: ["MIT"],
      links: %{
        GitHub: @url
      }
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:broadway_kafka, "~> 0.3"},
      {:aws_signature, "~> 0.3.0"},
      {:ex_aws, "~> 2.3"},
      {:ex_aws_sts, "~> 2.3"},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      {:jason, "~> 1.3"},
      {:hammox, "~> 0.5", only: :test},
      {:styler, "~> 1.0.0-rc.1", only: [:dev, :test], runtime: false}
    ]
  end

  defp docs do
    [
      main: "readme",
      source_ref: "v#{@version}",
      source_url: @url,
      extras: ["README.md"]
    ]
  end
end
