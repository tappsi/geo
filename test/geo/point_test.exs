defmodule Geo.PointTest do
  use ExUnit.Case, async: true

  alias Geo.Geometry.Point

  @geometry_record {:geometry, 2, [{4.00, 4.00}, {-77.0, -77.0}], :undefined}

  test "create new point from valid numbers" do
    latitude  = 4.00
    longitude = -77.0
    point = Point.new(latitude, longitude)

    assert 4.00 = Point.latitude(point)
    assert -77.0  = Point.longitude(point)
    assert {4.00, -77.0} = Point.latlon(point)
  end

  test "raise on invalid coordinates" do
    assert_raise Point.InvalidCoordinates, ~r/are not valid coordinates/, fn ->
      Point.new("a", "b")
    end
  end

  test "convert from record" do
    assert %Point{} = Point.to_point(@geometry_record)
  end
end
