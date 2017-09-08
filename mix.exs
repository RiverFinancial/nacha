defmodule Nacha.Mixfile do
  use Mix.Project

  def project do
    [
      app: :nacha,
      version: "0.0.1",
      elixir: "~> 1.5",
      start_permanent: Mix.env == :prod,
      description: description(),
      package: package(),
      deps: deps(),
      name: "Nacha",
      source_url: "https://github.com/tokkenops/nacha.ex"
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    []
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_doc, ">= 0.0.0", only: :dev}
    ]
  end

  defp description do
    """
    ** WIP **
    An Elixir library for generating and parsing NACHA files for US ACH and
    EFT bank transfers.
    """
  end

  defp package do
    [
      maintainers: ["Brent Yoder"],
      licenses: ["Apache 2.0"],
      links: %{"GitHub" => "https://github.com/tokkenops/nacha.ex"}
    ]
  end
end
