defmodule ExKpl.MixProject do
  use Mix.Project

  def project do
    [
      app: :ex_kpl,
      version: "0.1.0",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ],
      name: "ExKpl",
      source_url: "https://github.com/sneako/ex_kpl",
      description: "Kinesis Producer Library in Elixir",
      package: package()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:exprotobuf, "~> 1.2"},
      {:excoveralls, "~> 0.8.1", only: :test},
      {:ex_doc, ">= 0.0.0", only: :dev}
    ]
  end

  defp package do
    [
      maintainers: ["Nico Piderman"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/sneako/ex_kpl"}
    ]
  end
end
