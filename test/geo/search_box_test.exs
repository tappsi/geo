defmodule Geo.SeachBoxTest do
  use ExUnit.Case, async: true

  alias Geo.Geometry.{SearchBox, Point}

  test "center of a given search box" do
    point = Point.new(4.0, -77.0)
    search_box = SearchBox.new(point, 400)

    assert ^point = SearchBox.center(search_box)
  end

  test "area of a given search box" do
    search_box = Point.new(4.6097100, -74.0817500) |> SearchBox.new(4_000)

    assert 0.011736530598231789 = SearchBox.area(search_box)
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

  # Internal functions

  defp assert_close(a, b), do: assert trunc(a * 10_000) == trunc(b * 10_000)
end
