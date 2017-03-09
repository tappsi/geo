defmodule Geo.Mixfile do
  use Mix.Project

  @version "0.1.0"

  def project do
    [app: :geo,
     name: "Geo",
     source_url: "https://github.com/tappsi/geo",
     homepage_url: "https://github.com/tappsi/geo",
     version: @version,
     elixir: "~> 1.4",
     description: description(),
     docs: docs(),
     package: package(),
     deps: deps(),
     test_coverage: [tool: ExCoveralls],
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod]
  end

  def application do
    [extra_applications: [:logger],
     mod: {Geo, []}]
  end

  defp description do
    "Geometry on the Earth's surface in a 2D plane"
  end

  def docs do
    [source_ref: "v#{@version}",
     main: "Geo",
     extras: ["README.md", "CONTRIBUTING.md", "CHANGELOG.md"]]
  end

  defp package do
    [files: ~w(lib test mix.exs README.md LICENSE VERSION),
     maintainers: ["Oscar Moreno", "Ricardo Lanziano"],
     licenses: ["MIT"],
     links: %{"GitHub" => "https://github.com/tappsi/geo"}]
  end

  defp deps do
    [{:rstar, github: "armon/erl-rstar"},

     # Development
     {:excoveralls, "> 0.0.0", only: :test},

     # Documentation
     {:ex_doc, "> 0.0.0", only: :docs},
     {:earmark, "> 0.0.0", only: :docs}]
  end
end
