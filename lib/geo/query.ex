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
  alias Geo.Distance

  @doc """
  Search around the `zone` for a given `point`

  A new `SearchBox` is created for adjusting the latitude using the
  `distance` as padding.

  `distance` is in meters.
  """
  @spec around(Zone.t, Point.t, non_neg_integer) :: [Point.t]
  def around(%Zone{}=zone, %Point{}=point, distance) when distance > 0 do
    search_box = SearchBox.new(point, distance)

    Zone.search_within(zone, search_box)
    |> Enum.filter(&(Distance.harvesine(point, &1) <= distance))
  end

  @doc """
  Search around the `zone` for a given `point`

  We replace the `k` with `2 * k` and sort on true distance and select
  the first k.
  """
  @spec nearest(Zone.t, Point.t, non_neg_integer) :: [Point.t]
  def nearest(%Zone{}=zone, %Point{}=point, k) when k > 0 do
    Zone.search_nearest(zone, point, 2 * k)
    |> Enum.map(&({Distance.harvesine(point, &1), &1}))
    |> Enum.sort_by(&near/1, &<=/2)
    |> Enum.take(k)
  end

  # Internal functions

  defp near({distance, _}), do: distance
end
