defmodule Geo.Distance do
  @moduledoc """
  Geo distance implementations

  This API exports different distance measuring methods and
  algorithms.

  It currently implements:

    * Euclidean
    * Manhattan
    * Harvesines

  """

  alias Geo.Geometry.Point
  alias :math, as: Math

  @radius_meters 6378137.0              # Earth's radius in meters
  @degrees_to_rad 0.017453292519943295  # Multiplier to convert from degrees to radians

  @doc """
  Calculates the Euclidean distance between `a` and `b`

  It is defined as `dist((x, y), (a, b)) = √(x - a)² + (y - b)²`

  ## Caveats

  Euclidean distance is pretty good for relative small areas but
  overall it's not accurate given Earth's ellipticity. It works on ℝ².
  """
  @spec euclidean(Point.t, Point.t) :: float
  def euclidean(%Point{}=a, %Point{}=b) do
    {a_lat, a_lon} = Point.latlon(a)
    {b_lat, b_lon} = Point.latlon(b)

    a_diff = a_lat - a_lon
    b_diff = b_lat - b_lon

    Math.sqrt(Math.pow(a_diff, 2) + Math.pow(b_diff, 2))
  end

  @doc """
  Calculates the Manhattan distance between `a` and `b`

  It is defined as `dist1((x1, y1),(x2, y2)) = |x2 - x1| + |y2 - y1|`
  """
  @spec manhattan(Point.t, Point.t) :: float
  def manhattan(%Point{}=a, %Point{}=b) do
    {a_lat, a_lon} = Point.latlon(a)
    {b_lat, b_lon} = Point.latlon(b)

    abs(b_lat - a_lat) + abs(b_lon - a_lon)
  end

  @doc """
  Estimates the distance in meters between point `a` and `b` using the
  [Law of Harvestines](http://en.wikipedia.org/wiki/Law_of_haversines)

  Provides a better estimate of distance than the Euclidean distance
  for the R-Tree.

  The result is in meters.

  ## Alternatives

  There are different approaches for measuring distances over
  spherical distances. We use Harvestines as our first approach but we
  need to take into consideration the implementation of more accurate
  methods for dealing with Earth's ellipticity, spherical sharding and
  indexing.

  ## More information

  - [Calculate distance, bearing and more between Latitude/Longitude
    points](http://www.movable-type.co.uk/scripts/latlong.html)

  """
  @spec harvesine(Point.t, Point.t) :: float
  def harvesine(%Point{}=a, %Point{}=b) do
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
end
