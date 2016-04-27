defmodule Geo.DistanceTest do
  use ExUnit.Case, async: true

  alias Geo.Distance
  alias Geo.Geometry.Point

  test "euclidean distance" do
    a = Point.new(2, -1)
    b = Point.new(-2, 2)

    assert 5.0 = Distance.euclidean(a, b)
  end

  test "manhattan distance" do
    a = Point.new(1, 4)
    b = Point.new(3, 1)

    assert 5 = Distance.manhattan(a, b)
  end

  test "harvesine distance truncated" do
    a = Point.new(47.123, 120.567)
    b = Point.new(45.876, 123.876)

    assert 289038078 == trunc(1_000 * Distance.harvesine(a, b))
  end

  test "harvesine nearby distance" do
    a = Point.new(47.123, 120.567)
    b = Point.new(47.276, 120.576)

    assert 17045.480008358903 == Distance.harvesine(a, b)
  end
end
