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

  test "latitudinal widths" do
    # According to https://en.wikipedia.org/wiki/Latitude#Length_of_a_degree_of_latitude

    assert 110574 = round(SearchBox.latitudinal_width(0))
    assert 110649 = round(SearchBox.latitudinal_width(15))
    assert 110852 = round(SearchBox.latitudinal_width(30))
    assert 111132 = round(SearchBox.latitudinal_width(45))
    assert 111412 = round(SearchBox.latitudinal_width(60))
    assert 111618 = round(SearchBox.latitudinal_width(75))
    assert 111694 = round(SearchBox.latitudinal_width(90))
  end

  test "longitudinal widths" do
    # According to https://en.wikipedia.org/wiki/Latitude#Length_of_a_degree_of_latitude

    assert 111319 = round(SearchBox.longitudinal_width(0))
    assert 107550 = round(SearchBox.longitudinal_width(15))
    assert 96486  = round(SearchBox.longitudinal_width(30))
    assert 78847  = round(SearchBox.longitudinal_width(45))
    assert 55800  = round(SearchBox.longitudinal_width(60))
    assert 28902  = round(SearchBox.longitudinal_width(75))
    assert 0      = round(SearchBox.longitudinal_width(90))
  end

  # Internal functions

  defp assert_close(a, b), do: assert trunc(a * 10_000) == trunc(b * 10_000)
end
