defmodule ExKpl.MixProject do
  use Mix.Project

  def project do
    [
      app: :ex_kpl,
      version: "0.2.0",
      elixir: "~> 1.7",
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
      {:protox, "~> 2.0"},
      {:benchee, "~> 1.0", only: :dev},
      {:dialyxir, "~> 1.0", only: [:test, :dev], runtime: false},
      {:excoveralls, "~> 0.13.2", only: :test},
      {:ex_doc, "~> 0.22", only: :dev, runtime: false}
    ]
  end

  defp package do
    [
      maintainers: ["Nico Piderman"],
      files: ["lib", "priv", "mix.exs", "README*", "LICENSE*", "proto"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/sneako/ex_kpl"}
    ]
  end
end
