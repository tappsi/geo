defmodule Geo.QueryTest do
  use ExUnit.Case, async: true

  alias Geo.Geometry.{Point, Zone, SearchBox}
  alias Geo.Query

  @bogota Point.new(4.598056, -74.075833, "Bogotá")

  @point_a Point.new(4.634562, -74.076297, "driver a")
  @point_b Point.new(4.631415, -74.074769, "driver b")
  @point_c Point.new(5.631415, -72.074769, "driver c")

  @booking_a Point.new(4.634999, -74.071882, "booking a")
  @booking_b Point.new(4.626682, -74.071308, "booking b")

  test "distance" do
    a = Point.new(47.123, 120.567)
    b = Point.new(45.876, 123.876)

    assert 289038078 == trunc(1_000 * Query.distance(a, b))
  end

  test "nearby distance" do
    a = Point.new(47.123, 120.567)
    b = Point.new(47.276, 120.576)

    assert 17045.480008358903 == Query.distance(a, b)
  end

  test "search around the zone" do
    zone =
      Zone.new(2)
      |> Zone.add_point(@point_a)
      |> Zone.add_point(@point_b)
      |> Zone.add_point(@point_c)

    Query.around(zone, @booking_a, 500) # 500m
    |> Enum.each(&(assert &1 == @point_a))

    Query.around(zone, @booking_b, 1_000) # 1km
    |> Enum.each(&(assert &1 == @point_b))

    Query.around(zone, @booking_a, 1_000) # 1km
    |> Enum.each(&(assert &1 in [@point_a, @point_b]))
  end

  test "search near the zone" do
    zone =
      Zone.new(2)
      |> Zone.add_point(@point_a)
      |> Zone.add_point(@point_b)
      |> Zone.add_point(@point_c)

    distance = Query.distance(@point_a, @booking_a)

    assert [{^distance, @point_a}| _] = Query.nearest(zone, @booking_a, 10)
  end

  test "search box equator" do
    point = Point.new(0, 0)
    box   = SearchBox.new(point, 10_000) # 10km

    [{min_lat, max_lat}, {min_lng, max_lng}] = SearchBox.min_max(box)

    assert -0.13565538330708235 = min_lat
    assert 0.13565538330708235  = max_lat
    assert -0.1347476677660395  = min_lng
    assert 0.1347476677660395   = max_lng
  end

  test "search box offset" do
    point = Point.new(45, -120)
    box = SearchBox.new(point, 10_000) # 10km

    [{min_lat, max_lat}, {min_lng, max_lng}] = SearchBox.min_max(box)

    assert_close 45.0 - 0.134974625, min_lat
    assert_close 45.0 + 0.134974625, max_lat
    assert_close -120.0 - 0.19069, min_lng
    assert_close -120.0 + 0.19069, max_lng
  end

  test "latitudinal widths" do
    # According to https://en.wikipedia.org/wiki/Latitude#Length_of_a_degree_of_latitude

    assert 110574 = round(Query.latitudinal_width(0))
    assert 110649 = round(Query.latitudinal_width(15))
    assert 110852 = round(Query.latitudinal_width(30))
    assert 111132 = round(Query.latitudinal_width(45))
    assert 111412 = round(Query.latitudinal_width(60))
    assert 111618 = round(Query.latitudinal_width(75))
    assert 111694 = round(Query.latitudinal_width(90))
  end

  test "longitudinal widths" do
    # According to https://en.wikipedia.org/wiki/Latitude#Length_of_a_degree_of_latitude

    assert 111319 = round(Query.longitudinal_width(0))
    assert 107550 = round(Query.longitudinal_width(15))
    assert 96486  = round(Query.longitudinal_width(30))
    assert 78847  = round(Query.longitudinal_width(45))
    assert 55800  = round(Query.longitudinal_width(60))
    assert 28902  = round(Query.longitudinal_width(75))
    assert 0      = round(Query.longitudinal_width(90))
  end

  # Internal functions

  defp assert_close(a, b), do: assert trunc(a * 10_000) == trunc(b * 10_000)
end
