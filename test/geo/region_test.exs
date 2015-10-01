defmodule Geo.RegionTest do
  use ExUnit.Case, async: false

  alias Geo.Region
  alias Geo.Geometry.Point

  @bogota    Point.new(4.598056, -74.075833, "Bogotá")

  @booking_a Point.new(4.634999, -74.071882, "booking a")
  @point_a   Point.new(4.634562, -74.076297, "driver a")

  @booking_b Point.new(4.626682, -74.071308, "booking b")
  @point_b   Point.new(4.631415, -74.074769, "driver b")

  setup do
    on_exit fn ->
      Region.all
      |> Enum.each fn {region, _pid} ->
        Region.shutdown(region)
      end
    end

    {:ok, region} = Region.new("Bogotá", 4.598056, -74.075833)

    GenServer.call(region, {:add_object, "driver b", @point_b})
    GenServer.call(region, {:add_object, "driver a", @point_a})

    {:ok, [region: region]}
  end

  test "Can store a new location", %{region: region} do
    assert :ok = GenServer.call(region, {:add_object, "other driver", @point_a})
  end

  test "Can't add the same location twice", %{region: region} do
    assert :ok = GenServer.call(region, {:add_object, "other driver", @point_a})
    assert :already_added = GenServer.call(region, {:add_object, "other driver", @point_a})
  end

  test "Can locate nearby objects", %{region: region} do
    assert {:ok, [@point_a]} = GenServer.call(region, {:query_around, @booking_a, 500})
    assert {:ok, [@point_b]} = GenServer.call(region, {:query_around, @booking_b, 1_000})
  end

  test "Stored objects", %{region: region} do
    assert {:ok, drivers} = GenServer.call(region, :list_objects)
    assert is_list(drivers)
    refute is_nil(drivers)
  end

  test "Delete an stored object", %{region: region} do
    assert :ok = GenServer.call(region, {:remove_object, "driver a"})
  end

  test "Can't delete an unknown object", %{region: region} do
    assert :not_found = GenServer.call(region, {:remove_object, "driver aa"})
  end
end
