defmodule Geo.Mixfile do
  use Mix.Project

  @version "0.0.1"

  def project do
    [app: :geo,
     name: "Geo",
     source_url: "https://github.com/tappsi/geo",
     homepage_url: "https://github.com/tappsi/geo",
     version: @version,
     description: description,
     docs: docs,
     elixir: "~> 1.1",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps]
  end

  def application do
    [applications: [:logger, :rstar],
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

  defp deps do
    [{:rstar, github: "armon/erl-rstar"},

     # Documentation
     {:ex_doc, "~> 0.10", only: :docs},
     {:earmark, "~> 0.1", only: :docs}]
  end
end
