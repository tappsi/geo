defmodule Geo.RegionTest do
  use ExUnit.Case, async: false

  alias Geo.Region
  alias Geo.Geometry.Point

  @booking_a Point.new(4.634999, -74.071882, "booking a")
  @point_a   Point.new(4.634562, -74.076297, "driver a")

  @booking_b Point.new(4.626682, -74.071308, "booking b")
  @point_b   Point.new(4.631415, -74.074769, "driver b")

  setup do
    on_exit fn ->
      Region.all
      |> Enum.each(fn {region, _pid} ->
        Region.shutdown(region)
      end)
    end

    {:ok, region} = Region.new("Bogotá", 4.598056, -74.075833)

    Region.add_object(region, "driver b", @point_b)
    Region.add_object(region, "driver a", @point_a)

    {:ok, [region: region]}
  end

  test "Can store a new location", %{region: region} do
    assert :ok = Region.add_object(region, "other driver", @point_a)
  end

  test "Can't add the same location twice", %{region: region} do
    assert :ok = Region.add_object(region, "other driver", @point_a)
    assert :already_added = Region.add_object(region, "other driver", @point_a)
  end

  test "Can locate nearby objects", %{region: region} do
    assert {:ok, [@point_a]} = Region.query_around(region, @booking_a, 500)
    assert {:ok, [@point_b]} = Region.query_around(region, @booking_b, 1_000)
  end

  test "Stored objects", %{region: region} do
    assert {:ok, drivers} = Region.list_objects(region)
    assert is_list(drivers)
    refute is_nil(drivers)
  end

  test "Delete an stored object", %{region: region} do
    assert :ok = Region.remove_object(region, "driver a")
  end

  test "Can't delete an unknown object", %{region: region} do
    assert :not_found = Region.remove_object(region, "driver aa")
  end
end
