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
  alias :math, as: Math

  @radius_meters 6378137.0              # Earth's radius in meters
  @degrees_to_rad 0.017453292519943295  # Multiplier to convert from degrees to radians

  @pi   Math.pi                         # Inlined at compile-time for speed
  @e_sq 0.00669437999014                # e² inlined for speed

  @doc """
  Search around the `zone` for a given `point` using `distance` as
  padding

  We replace this query with a search rectangle that adjusts for
  narrowing longitude.

  `distance` is in meters.
  """
  def around(%Zone{}=zone, %Point{}=point, distance) when distance > 0 do
    search_box = SearchBox.new(point, distance)

    Zone.search_within(zone, search_box)
    |> Enum.filter(&(distance(point, &1) <= distance))
  end

  @doc """
  Search around the `zone` for a given `point`

  We replace the `k` with `2 * k` and sort on true distance and select
  the first k.
  """
  def nearest(%Zone{}=zone, %Point{}=point, k) do
    Zone.search_nearest(zone, point, 2 * k)
    |> Enum.map(&({distance(point, &1), &1}))
    |> Enum.sort_by(&near/1, &<=/2)
    |> Enum.take(k)
  end

  @doc """
  Estimates the distance in meters between two `Geo.Geometry.Point` `a` and `b`
  using the [Law of Harvestines](http://en.wikipedia.org/wiki/Law_of_haversines)

  Provides a better estimate of distance than the Euclidean distance
  for the R-Tree.

  The result is in meters.

  ## Alternatives

  There are different approaches for measuring distances over
  spherical distances. We use Harvestines as our first approach but we
  need to take into consideration the implementation of more accurate
  methods for dealing with Earth's ellipticity, spherical sharding and
  indexing.
  """
  def distance(a, b) do
    {lat_a, lng_a} = Point.latlon(a)
    {lat_b, lng_b} = Point.latlon(b)

    lat_arc = (lat_a - lat_b) * @degrees_to_rad
    lng_arc = (lng_a - lng_b) * @degrees_to_rad

    # Correct to 0.01 mt
    latitude_h  = Math.sin(lat_arc * 0.5) |> Math.pow(2) # φ = 0.5 degrees
    longitude_h = Math.sin(lng_arc * 0.5) |> Math.pow(2) # φ = 0.5 degrees

    t1 = Math.cos(lat_a * @degrees_to_rad) * Math.cos(lat_b * @degrees_to_rad)
    t2 = latitude_h + t1 * longitude_h

    distance_angle = 2.0 * Math.asin(Math.sqrt(t2))
    distance_angle * @radius_meters
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
