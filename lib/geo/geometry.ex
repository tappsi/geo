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

defmodule Geo.Geometry.Point do
  @moduledoc ~S"""
  2D point
  """

  require Record
  defstruct [:record]

  Record.defrecord :geometry,
    Record.extract(:geometry, from_lib: "rstar/include/rstar.hrl")

  @doc """
  Returns new 2D point from `lat` and `lon`
  """
  def new(lat, lon, value \\ :undefined) when is_number(lat) and is_number(lon) do
    %__MODULE__{record: :rstar_geometry.point2d(lat, lon, value)}
  end

  @doc "Returns the latitude for `arg`"
  def latitude(%__MODULE__{record: {:geometry, 2, [{lat, _}, {_, _}], _}}), do: lat

  @doc "Returns the longitude for `arg`"
  def longitude(%__MODULE__{record: {:geometry, 2, [{_, _}, {lng, _}], _}}), do: lng

  @doc "Returns the latitude and longitude for `arg`"
  def latlon(%__MODULE__{record: {:geometry, 2, [{lat, _}, {lng, _}], _}}) do
    {lat, lng}
  end
end

defimpl Inspect, for: Geo.Geometry.Point do
  alias Geo.Geometry.Point

  def inspect(point, _opts) do
    "#Point<[#{Point.latitude(point)}, #{Point.longitude(point)}]>"
  end
end

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

defmodule Geo.Geometry.Zone do
  @moduledoc ~S"""
  Zone wrapper
  """

  require Geo.Geometry.Point
  alias Geo.Geometry.{SearchBox, Point}

  defstruct [:record]

  @doc "Returns a new zone with the given `dimensions`"
  def new(dimensions) when dimensions < 1 do
    raise "invalid dimension"
  end
  def new(dimensions) do
    %__MODULE__{record: :rstar.new(dimensions)}
  end

  @doc "Adds a `point` to the `zone`"
  def add_point(%__MODULE__{record: zone}, point) do
    %__MODULE__{record: :rstar.insert(zone, point.record)}
  end

  @doc "Deletes a `point` from the `zone`"
  def delete_point(%__MODULE__{record: zone}, point) do
    %__MODULE__{record: :rstar.delete(zone, point.record)}
  end

  def to_point({:geometry, _, [{_, _}, {_, _}], _}=record) do
    %Point{record: record}
  end

  @doc "Search within the `zone` for a given `search_box`"
  def search_within(%__MODULE__{record: zone}, %SearchBox{record: search_box}) do
    :rstar.search_within(zone, search_box)
    |> Enum.map(&to_point(&1))
  end

  @doc """
  Search the nearest `k` points contained inside the `zone` from
  `search_point`

    * `k` is the padding distance in meters
  """
  def search_nearest(%__MODULE__{record: zone}, %Point{record: search_point}, k)
  when is_number(k) do
    :rstar.search_nearest(zone, search_point, k)
    |> Enum.map(&to_point(&1))
  end

  @doc """
  Search the points contained or intersecting in the given
  `search_point`
  """
  def search_around(%__MODULE__{record: zone}, %Point{record: search_point}, distance)
  when is_number(distance) do
    :rstar.search_around(zone, search_point, distance)
  end
end

defimpl Inspect, for: Geo.Geometry.Zone do
  def inspect(zone, _opts) do
    "#Zone<[#{Kernel.elem(zone.record, 1)}]>"
  end
end
