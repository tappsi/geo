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

  @doc "Wraps the `:geometry` record into a `%Point{}`"
  def to_point({:geometry, _, [{_, _}, {_, _}], _}=record) do
    %__MODULE__{record: record}
  end
end

defimpl Inspect, for: Geo.Geometry.Point do
  alias Geo.Geometry.Point

  def inspect(point, _opts) do
    "#Point<[#{Point.latitude(point)}, #{Point.longitude(point)}]>"
  end
end
