defmodule Microformats2.Mixfile do
  use Mix.Project

  def project do
    [
      app: :microformats2,
      version: "0.2.1",
      elixir: "~> 1.6",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      deps: deps()
    ]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [applications: [:logger]]
  end

  def description do
    """
    A microformats2 parser (http://microformats.org/wiki/microformats-2) for Elixir
    """
  end

  def package do
    [
      files: ["lib", "mix.exs", "README.md", "LICENSE"],
      maintainers: ["Christian Kruse"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/ckruse/microformats2-elixir"}
    ]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [
      {:floki, "~> 0.7"},
      {:httpotion, "~> 3.0", optional: true},
      {:ex_doc, ">= 0.0.0", only: :dev}
    ]
  end
end
