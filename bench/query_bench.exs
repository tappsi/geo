defmodule Geo.QueryBench do
  use Benchfella

  alias Geo.Query
  alias Geo.Geometry.Point
  alias Geo.Geometry.Zone
  alias Geo.Geometry.SearchBox

  @empty_rtree  Zone.new(2)
  @point_a      Point.new(4.309493, -77.38723)
  @point_b      Point.new(4.957344, -77.98254)
  @search_box   SearchBox.new(@point_b, 10_000)

  setup_all do
    points =
      for point <- 1..50_000 do
        Point.new(Random.normal(4.9573, -77.9825),
                  Random.normal(4.9573, -77.9825), point)
      end

    zone =
      points
      |> List.foldr Zone.new(2), fn(point, zone) ->
        Zone.add_point(zone, point)
      end

    {:ok, zone}
  end

  before_each_bench zone do
    {:ok, zone}
  end

  bench "Query nearest (loaded Zone)", [zone: bench_context] do
    Query.nearest(bench_context, @search_box, 10_000) # 10km
  end

  bench "Query around (loaded Zone)", [zone: bench_context] do
    Query.around(bench_context, @point_a, 10_000)
  end

  bench "Inserting points into an empty Zone" do
    Zone.add_point(@empty_rtree, @point_a)
  end

  bench "Inserting points into a loaded Zone", [zone: bench_context] do
    Zone.add_point(bench_context, @point_a)
  end

  bench "Calculating nearby distance" do
    Query.distance(@point_a, @point_b)
  end

  bench "Query nearest (empty Zone)" do
    Query.nearest(@empty_rtree, @search_box, 10_000)
  end

  bench "Query around (empty Zone)" do
    Query.around(@empty_rtree, @point_a, 10_000)
  end
end

defmodule Random do
  def init, do: :random.seed :erlang.timestamp

  def normal(mean, sd) do
    {a, b} = {:random.uniform, :random.uniform}
    mean + sd * (:math.sqrt(-2 * :math.log(a)) * :math.cos(2 * :math.pi * b))
  end
end
