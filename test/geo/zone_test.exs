defmodule Geo.ZoneTest do
  use ExUnit.Case, async: true

  alias Geo.{Query, Distance}
  alias Geo.Geometry.{Zone, SearchBox, Point}

  @booking_a Point.new(4.634999, -74.071882, "booking a")

  @point_a Point.new(4.634562, -74.076297, "driver a")
  @point_b Point.new(4.631415, -74.074769, "driver b")
  @point_c Point.new(5.631415, -72.074769, "driver c")

  test "raises on invalid dimensions" do
    assert_raise Zone.InvalidDimension, ~r/0 is not a valid number of dimensions/, fn ->
      Zone.new(0)
    end
  end

  test "search within a zone" do
    zone =
      Zone.new(2)
      |> Zone.add_point(@point_a)
      |> Zone.add_point(@point_b)
      |> Zone.add_point(@point_c)

    search_box = SearchBox.new(@point_a, 40) # 40m

    assert [@point_a] = Zone.search_within(zone, search_box)
  end

  test "search near the zone" do
    zone =
      Zone.new(2)
      |> Zone.add_point(@point_a)
      |> Zone.add_point(@point_b)
      |> Zone.add_point(@point_c)

    distance = Distance.harvesine(@point_a, @booking_a)

    assert [{^distance, @point_a}| _] = Query.nearest(zone, @booking_a, 10)
  end
end
