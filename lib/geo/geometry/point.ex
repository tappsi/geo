defmodule Geo.Geometry.Point do
  @moduledoc ~S"""
  2D point
  """

  defmodule InvalidCoordinates do
    @moduledoc """
    Raised when one of the `latitude` or `longitude` is not a valid number.
    """

    defexception [:message]

    def exception([lat: lat, lon: lon]) do
      msg = "#{inspect lat}, #{inspect lon} are not valid coordinates"
      %InvalidCoordinates{message: msg}
    end
  end

  require Record
  defstruct [:record]

  @type latitude  :: float
  @type longitude :: float
  @type value     :: term()
  @type geometry  :: {atom(), non_neg_integer, list(), term()}

  @type t :: %__MODULE__{record: geometry}

  Record.defrecord :geometry,
    Record.extract(:geometry, from_lib: "rstar/include/rstar.hrl")

  @doc """
  Returns new 2D point from `lat` and `lon`

  It raises a `InvalidCoordinates` exception if `lat` and `lon` are
  not numbers.
  """
  @spec new(latitude, longitude, any()) :: Point.t
  def new(lat, lon, value \\ :undefined)

  def new(lat, lon, value) when is_number(lat) and is_number(lon) do
    %__MODULE__{record: :rstar_geometry.point2d(lat, lon, value)}
  end
  def new(lat, lon, _value), do: raise InvalidCoordinates, lat: lat, lon: lon

  @doc "Returns the latitude for `arg`"
  @spec latitude(Point.t) :: latitude
  def latitude(%__MODULE__{record: {:geometry, 2, [{lat, _}, {_, _}], _}}), do: lat

  @doc "Returns the longitude for `arg`"
  @spec longitude(Point.t) :: longitude
  def longitude(%__MODULE__{record: {:geometry, 2, [{_, _}, {lng, _}], _}}), do: lng

  @doc "Returns the latitude and longitude for `arg`"
  @spec latlon(Point.t) :: {latitude, longitude}
  def latlon(%__MODULE__{record: {:geometry, 2, [{lat, _}, {lng, _}], _}}) do
    {lat, lng}
  end

  @doc "Wraps the `:geometry` record into a `%Point{}`"
  @spec to_point(geometry) :: Point.t
  def to_point({:geometry, _, [{_, _}, {_, _}], _}=record) do
    %__MODULE__{record: record}
  end

  @doc "Define or replace `:value` field for given `%Point{}`"
  @spec set_value(geometry, value) :: Point.t
  def set_value(%__MODULE__{record: {:geometry, 2, coords, _}}, value) do
    %__MODULE__{record: {:geometry, 2, coords, value}}
  end

  @doc "Returns the value for `arg`"
  @spec value(geometry) :: term()
  def value(%__MODULE__{record: {:geometry, _, [{_, _}, {_, _}], value}}), do: value
end

defimpl Inspect, for: Geo.Geometry.Point do
  alias Geo.Geometry.Point

  def inspect(point, _opts) do
    "#Point<[#{Point.latitude(point)}, #{Point.longitude(point)}]>"
  end
end
