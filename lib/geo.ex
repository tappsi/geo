defmodule Geo do
  @moduledoc ~S"""
  `Geo` is a library for issuing queries and interacting with
  distances, shapes and locations on the Earth's surface in a 2D
  plane.

  It currently offers with the following modules:

    * `Geo.Query` - Provides the proximity engine and helpers for
      working with Euclidean distances on Earth's surface in a 2D
      plane

    * `Geo.Geometry` - Provides different abstractions for wrapping
      geolocation points. It allows creation and querying on 2D shapes

    * `Geo.Distance` - Provides different distance measurement
      functions for public use.

    * `Geo.Region` - Provides the facilities for creating regions of
      multiple `Geo.Geometry.Zone` and a basic API for storing,
      forgetting and querying different `Geo.Geometry.Point` on such
      zones

  ## Overview

  `Geo.Geometry` offers different shapes we can use for doing queries
  against different coordinates.

  ### Example

      iex> a = Geo.Geometry.Point.new(47.123, 120.567)
      #Point<47.123, 120.567>
      iex> b = Geo.Geometry.Point.new(47.321, 120.765)
      #Point<47.123, 120.567>
      iex> Geo.Query.distance(a, b)
      26644.001978045664

  Another example that stores two points with opaque values and
  queries about the nearest one:

      iex> a = Geo.Geometry.Point.new(4.634562, -74.076297, "point a")
      #Point<4.634562, -74.076297>
      iex> x = Geo.Geometry.Point.new(4.631415, -74.074769, "point x")
      #Point<4.631415, -74.074769>
      iex> y = Geo.Geometry.Point.new(4.631420, -74.074770, "point y")
      #Point<4.63142, -74.07477>
      iex> Geo.Geometry.Zone.new(2)
           |> Geo.Geometry.Zone.add_point(x)
           |> Geo.Geometry.Zone.add_point(y)
           |> Geo.Query.search_around(a, 389)
      [#Point<4.63142, -74.07477>]


  Check the corresponding module in order to learn about the current
  featureset.
  """

  use Application

  @doc "Start the `Geo` application"
  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      supervisor(Geo.Region.Supervisor, [])
    ]

    opts = [strategy: :one_for_one, name: Geo.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
