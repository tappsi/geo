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

  Record.defrecord :geometry, Record.extract(:geometry,
                                             from_lib: "rstar/include/rstar.hrl")

  @doc """
  Returns new 2D point from `lat` and `lon`
  """
  def new(lat, lon, value \\ :undefined) when is_number(lat) and is_number(lon) do
    :rstar_geometry.point2d(lat, lon, value)
  end

  @doc "Returns the latitude for `arg`"
  def latitude({:geometry, 2, [{lat, _}, {_, _}], _}), do: lat

  @doc "Returns the longitude for `arg`"
  def longitude({:geometry, 2, [{_, _}, {lng, _}], _}), do: lng

  @doc "Returns the latitude and longitude for `arg`"
  def latlon({:geometry, 2, [{lat, _}, {lng, _}], _}) do
    {lat, lng}
  end
end

defmodule Geo.Geometry.Zone do
  @moduledoc ~S"""
  Zone wrapper
  """

  @doc "Returns a new zone with the given `dimensions`"
  def new(dimensions) when dimensions < 1 do
    raise "invalid dimension"
  end
  def new(dimensions) do
    :rstar.new(dimensions)
  end

  @doc "Adds a `point` to the `zone`"
  def add_point(zone, point) do
    :rstar.insert(zone, point)
  end

  @doc "Deletes a `point` from the `zone`"
  def delete_point(zone, point) do
    :rstar.delete(zone, point)
  end

  @doc "Search within the `zone` for a given `search_box`"
  def search_within(zone, search_box) do
    :rstar.search_within(zone, search_box)
  end

  @doc """
  Search the nearest `k` points contained inside the `zone` from
  `search_point`

    * `k` is the padding distance in meters
  """
  def search_nearest(zone, search_point, k) when is_number(k) do
    :rstar.search_nearest(zone, search_point, k)
  end

  @doc """
  Search the points contained or intersecting in the given
  `search_point`
  """
  def search_around(zone, search_point, distance) when is_number(distance) do
    :rstar.search_around(zone, search_point, distance)
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

  @padding 1.5

  @doc """
  Generates a search box from a `search_point` and `distance`

  We compute the width of a degree using the latitude and longitude
  from the `search_point` to create a bounding box using the padded
  `distance` and the computed width.

  ## Example

      iex> point = Geo.Geometry.Point(4.0, -77.0)
      {:geometry, ...}
      iex> Geo.Geometry.SearchBox.new(point, 400)
      {:geometry, ...}

  """
  def new(search_point, distance, value \\ :undefined) do
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

    coords  = [{min_lat, max_lat}, {min_lng, max_lng}]

    Point.geometry(dimensions: 2, mbr: coords, value: value)
  end

  @doc "Returns the area of the given `search_box`"
  def area(search_box) do
    :rstar_geometry.area(search_box)
  end

  @doc "Returns the margin of the given `search_box`"
  def margin(search_box) do
    :rstar_geometry.margin(search_box)
  end

  @doc "Returns the overlapping search box from `a` and `b`"
  def intersect(a, b) do
    :rstar_geometry.intersect(a, b)
  end

  @doc "Returns the center of the given `search_box`"
  def center(search_box) do
    :rstar_geometry.center(search_box)
  end
end
