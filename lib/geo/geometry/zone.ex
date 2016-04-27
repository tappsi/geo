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

  @doc "Search within the `zone` for a given `search_box`"
  def search_within(%__MODULE__{record: zone}, %SearchBox{record: search_box}) do
    :rstar.search_within(zone, search_box)
    |> Enum.map(&Point.to_point(&1))
  end

  @doc """
  Search the nearest `k` points contained inside the `zone` from
  `search_point`

    * `k` is the padding distance in meters
  """
  def search_nearest(%__MODULE__{record: zone}, %Point{record: search_point}, k)
  when is_number(k) do
    :rstar.search_nearest(zone, search_point, k)
    |> Enum.map(&Point.to_point(&1))
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
