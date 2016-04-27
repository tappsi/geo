defmodule Geo.Geometry.Zone do
  @moduledoc ~S"""
  Zone wrapper
  """

  defmodule InvalidDimension do
    @moduledoc """
    Raised when the specified dimension is less than 1.
    """

    defexception [:message]

    def exception([dimensions: d]) do
      msg = "#{inspect d} is not a valid number of dimensions"
      %InvalidDimension{message: msg}
    end
  end

  require Geo.Geometry.Point
  alias Geo.Geometry.{SearchBox, Point}

  defstruct [:record]

  @type geometry  :: {atom(), non_neg_integer, list(), term()}
  @type dimension :: non_neg_integer

  @type t :: %__MODULE__{record: geometry}

  @doc "Returns a new zone with the given `dimensions`"
  @spec new(dimension) :: Zone.t
  def new(dimensions) when dimensions < 1 do
    raise InvalidDimension, dimensions: dimensions
  end
  def new(dimensions) do
    %__MODULE__{record: :rstar.new(dimensions)}
  end

  @doc "Adds a `point` to the `zone`"
  @spec add_point(Zone.t, Point.t) :: Zone.t
  def add_point(%__MODULE__{record: zone}, point) do
    %__MODULE__{record: :rstar.insert(zone, point.record)}
  end

  @doc "Deletes a `point` from the `zone`"
  @spec delete_point(Zone.t, Point.t) :: Zone.t
  def delete_point(%__MODULE__{record: zone}, point) do
    %__MODULE__{record: :rstar.delete(zone, point.record)}
  end

  @doc "Search within the `zone` for a given `search_box`"
  @spec search_within(Zone.t, SearchBox.t) :: [Point.t]
  def search_within(%__MODULE__{record: zone}, %SearchBox{record: search_box}) do
    :rstar.search_within(zone, search_box)
    |> Enum.map(&Point.to_point(&1))
  end

  @doc """
  Search the nearest `k` points contained inside the `zone` from
  `search_point`

    * `k` is the padding distance in meters
  """
  @spec search_nearest(Zone.t, Point.t, non_neg_integer) :: [Point.t]
  def search_nearest(%__MODULE__{record: zone}, %Point{record: search_point}, k)
  when is_number(k) do
    :rstar.search_nearest(zone, search_point, k)
    |> Enum.map(&Point.to_point(&1))
  end

  @doc """
  Search the points contained or intersecting in the given
  `search_point`
  """
  @spec search_around(Zone.t, Point.t, float) :: [Point.t]
  def search_around(%__MODULE__{record: zone}, %Point{record: search_point}, distance)
  when is_number(distance) do
    :rstar.search_around(zone, search_point, distance)
    |> Enum.map(&Point.to_point(&1))
  end
end

defimpl Inspect, for: Geo.Geometry.Zone do
  def inspect(zone, _opts) do
    "#Zone<[#{Kernel.elem(zone.record, 1)}]>"
  end
end
