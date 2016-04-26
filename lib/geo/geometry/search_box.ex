defmodule Geo.Geometry.SearchBox do
  @moduledoc ~S"""
  2D search box

  A search box is a bounded box padded according to a distance.
  """

  require Geo.Geometry.Point
  alias Geo.Geometry.Point
  alias Geo.Query

  defstruct [:record]

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
    lat_spread = distance_pad / Query.latitudinal_width(lat)
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

    lng_spread = distance_pad / Query.longitudinal_width(widest_lat)
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
    :rstar_geometry.center(search_box) |> to_point()
  end

  @doc "Returns the min and max pair for latitude and longitude coordinates"
  def min_max(%__MODULE__{record: search_box}) do
    elem(search_box, 2)
  end

  def to_point({:geometry, _, [{_, _}, {_, _}], _}=record) do
    %Point{record: record}
  end
end

defimpl Inspect, for: Geo.Geometry.SearchBox do
  def inspect(search_box, _opts) do
    {_, _, [{lat_a, lat_b}, {lon_a, lon_b}], _} = search_box.record
    "#SearchBox<[#{lat_a}, #{lat_b}], [#{lon_a}, #{lon_b}]>"
  end
end
