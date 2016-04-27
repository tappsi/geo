defmodule Geo.Geometry.SearchBox do
  @moduledoc ~S"""
  2D search box

  A search box is a bounded box padded according to a distance.
  """

  require Geo.Geometry.Point
  alias Geo.Geometry.Point
  alias :math, as: Math

  defstruct [:record]

  @radius_meters 6378137.0              # Earth's radius in meters
  @degrees_to_rad 0.017453292519943295  # Multiplier to convert from degrees to radians

  @pi   Math.pi                         # Inlined at compile-time for speed
  @e_sq 0.00669437999014                # e² inlined for speed

  @padding 1.5

  @doc """
  Generates a search box from a `search_point` and `distance`

  We compute the width of a degree using the latitude and longitude
  from the `search_point` to create a bounding box using the padded
  `distance` and the computed width.

  ## Example

      iex> point = Geo.Geometry.Point.new(4.0, -77.0)
      #Point<4.0, -77.0>
      iex> Geo.Geometry.SearchBox.new(point, 400)
      #SearchBox<[3.994574049778225, 4.005425950221775], [-77.00540300083401, -76.99459699916599]>

  """
  def new(%Point{}=search_point, distance, value \\ :undefined) do
    {lat, lng} = Point.latlon(search_point)

    # Pad the distance a bit so we over-query
    distance_pad = @padding * distance

    # Get the lat/lng binding box and compute the width
    lat_spread = distance_pad / latitudinal_width(lat)
    min_lat = lat - lat_spread
    max_lat = lat + lat_spread

    # The value farthest from the equator will result in
    # the smallest longitude width which creates the largest
    # spread in turn.
    widest_lat =
      cond do
        lat >= 0 -> max_lat
        lat < 0  -> min_lat
      end

    lng_spread = distance_pad / longitudinal_width(widest_lat)
    min_lng = lng - lng_spread
    max_lng = lng + lng_spread

    coords = [{min_lat, max_lat}, {min_lng, max_lng}]

    %__MODULE__{record: Point.geometry(dimensions: 2, mbr: coords, value: value)}
  end

  @doc "Returns the area of the given `search_box`"
  def area(%__MODULE__{record: search_box}) do
    :rstar_geometry.area(search_box)
  end

  @doc "Returns the margin of the given `search_box`"
  def margin(%__MODULE__{record: search_box}) do
    :rstar_geometry.margin(search_box)
  end

  @doc "Returns the overlapping search box from `a` and `b`"
  def intersect(%__MODULE__{record: a}, %__MODULE__{record: b}) do
    :rstar_geometry.intersect(a, b)
  end

  @doc "Returns the center of the given `search_box`"
  def center(%__MODULE__{record: search_box}) do
    :rstar_geometry.center(search_box) |> Point.to_point()
  end

  @doc "Returns the min and max pair for latitude and longitude coordinates"
  def min_max(%__MODULE__{record: search_box}) do
    elem(search_box, 2)
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
end

defimpl Inspect, for: Geo.Geometry.SearchBox do
  def inspect(search_box, _opts) do
    {_, _, [{lat_a, lat_b}, {lon_a, lon_b}], _} = search_box.record
    "#SearchBox<[#{lat_a}, #{lat_b}], [#{lon_a}, #{lon_b}]>"
  end
end
