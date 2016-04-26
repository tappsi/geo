defmodule Geo.Geometry do
  @moduledoc ~S"""
  Geometry module

  We use an [R-Tree](https://en.wikipedia.org/wiki/R-tree) to
  represent the surface of the Earth in a 2D plane. It is an excellent
  way to encode multi-dimensional information and allows for efficient
  query capabilities.

  It is the same structure used to represent the geographical
  search points in the `Geo.Query` module to implement its API.

  ## Points

  Our basic representation of a location is a `Geo.Geometry.Point`.

  ## Zones

  A `Geo.Geometry.Zone` is a placeholder for storing multiple
  `Geo.Geometry.Point` and perform distance queries against it.

  ## Other topics

  ### R-Trees and spatial indexes

  By using [R-Trees](https://en.wikipedia.org/wiki/R-tree) for storing
  the geolocation points we ensure that our table will increase its
  size to minimum.
  """
end
