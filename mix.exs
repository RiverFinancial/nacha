defmodule Nacha.Mixfile do
  use Mix.Project

  def project do
    [
      app: :nacha,
      version: "0.0.1",
      elixir: "~> 1.5",
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      aliases: aliases(),
      deps: deps(),
      name: "Nacha",
      source_url: "https://github.com/inabsentia/nacha.ex"
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    []
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_doc, ">= 0.0.0", only: :dev},
      {:mix_test_watch, "~> 0.8", only: :dev, runtime: false},
      {:dialyxir, "~> 1.0.0-rc.6", only: [:dev, :test], runtime: false}
    ]
  end

  defp description do
    """
    ** WIP **
    An Elixir library for generating and parsing NACHA files for US ACH and
    EFT bank transfers.
    """
  end

  defp aliases do
    [
      "lint.all": [
        "format --check-formatted",
        "dialyzer --halt-exit-status"
      ]
    ]
  end

  defp package do
    [
      maintainers: ["Brent Yoder"],
      licenses: ["Apache 2.0"],
      links: %{"GitHub" => "https://github.com/AltoFinancial/nacha"}
    ]
  end
end
