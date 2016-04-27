defmodule Geo.Query do
  @moduledoc ~S"""
  Query engine

  This module provides the basic API for searching around a given zone
  provided by `Geo.Geometry.Zone`.

  All functions takes into account the non-2D nature of the Earth.

  ## Observations

  Some of the assumptions made by `Geo.Query` are:

    * `6378137.0` as the Earth's radius in meters

    * `0.017453292519943295` as multiplier for converting from degrees
      to radians

    * `0.00669437999014` as [e²](https://en.wikipedia.org/wiki/Eccentricity_%28mathematics%29)
  """

  alias Geo.Geometry.{Point, Zone, SearchBox}
  alias Geo.Distance
  alias :math, as: Math

  @radius_meters 6378137.0              # Earth's radius in meters
  @degrees_to_rad 0.017453292519943295  # Multiplier to convert from degrees to radians

  @pi   Math.pi                         # Inlined at compile-time for speed
  @e_sq 0.00669437999014                # e² inlined for speed

  @doc """
  Search around the `zone` for a given `point`

  A new `SearchBox` is created for adjusting the latitude using the
  `distance` as padding.

  `distance` is in meters.
  """
  def around(%Zone{}=zone, %Point{}=point, distance) when distance > 0 do
    search_box = SearchBox.new(point, distance)

    Zone.search_within(zone, search_box)
    |> Enum.filter(&(Distance.harvesine(point, &1) <= distance))
  end

  @doc """
  Search around the `zone` for a given `point`

  We replace the `k` with `2 * k` and sort on true distance and select
  the first k.
  """
  def nearest(%Zone{}=zone, %Point{}=point, k) when k > 0 do
    Zone.search_nearest(zone, point, 2 * k)
    |> Enum.map(&({Distance.harvesine(point, &1), &1}))
    |> Enum.sort_by(&near/1, &<=/2)
    |> Enum.take(k)
  end

  @doc """
  Returns the width of a latitudinal degree in meters for the given
  `lat`

  See [Length of a degree of
  latitude](https://en.wikipedia.org/wiki/Latitude#Length_of_a_degree_of_latitude)
  """
  def latitudinal_width(lat) when is_number(lat) do
    lat_rad = lat * @degrees_to_rad

    # According to Meridian arc
    111132.954 - 559.822 * Math.cos(2.0 * lat_rad) + 1.175 * Math.cos(4.0 * lat_rad)
  end

  @doc """
  Returns the width of a longitudinal degree in meters for the given
  `lat`

  Earth is modelled as an ellipsoid. We use a
  [WGS84](https://en.wikipedia.org/wiki/World_Geodetic_System#WGS84)
  ellipsoid with `a = #{@radius_meters}` and have e² as extra
  parameter.
  """
  def longitudinal_width(lat) when is_number(lat) do
    lat_rad     = lat * @degrees_to_rad
    numerator   = @pi * @radius_meters * Math.cos(lat_rad)
    denominator = 180 * Math.sqrt(1 - @e_sq * Math.pow(Math.sin(lat_rad), 2))

    numerator / denominator
  end

  # Internal functions

  defp near({distance, _}), do: distance
end
