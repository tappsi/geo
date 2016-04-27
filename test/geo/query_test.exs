defmodule Geo.QueryTest do
  use ExUnit.Case, async: true

  alias Geo.Geometry.{Point, Zone}
  alias Geo.Query

  @bogota Point.new(4.598056, -74.075833, "Bogotá")

  @point_a Point.new(4.634562, -74.076297, "driver a")
  @point_b Point.new(4.631415, -74.074769, "driver b")
  @point_c Point.new(5.631415, -72.074769, "driver c")

  @booking_a Point.new(4.634999, -74.071882, "booking a")
  @booking_b Point.new(4.626682, -74.071308, "booking b")

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
end
