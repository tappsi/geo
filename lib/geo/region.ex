defmodule Geo.Region do
  @moduledoc ~S"""
  Region module

  A region is a server that stores zones.

  Each region can insert and forget locations on it's zones.

  ## Example

      iex> {:ok, region} = Geo.Region.new("Bogotá", 4.598056, -74.075833)
      {:ok, #PID<...>}
      iex> :ok = Geo.Region.add_object(region, "point a", point_a)
      :ok
      iex> :ok = Geo.Region.add_object(region, "point b", point_b)
      :ok
      iex> {:ok, points} = Geo.Region.query_around(region, point_c, 500)
      {:ok, [...]}
  """

  use GenServer

  alias Geo.Query
  alias Geo.Geometry.{Point, Zone, SearchBox}

  @default_radius   10_000 # 10km

  @region_sup Geo.Region.Supervisor

  # API

  @doc "Create a new region"
  def new(name, lat, lon) do
    Supervisor.start_child(@region_sup, [name, lat, lon])
  end

  @doc "Shutdown the `region`"
  def shutdown(region) do
    Supervisor.terminate_child(@region_sup, region)
  end

  @doc "List all registered objects in `region`"
  def list_objects(region) do
    GenServer.call(region, :list_objects)
  end

  @doc "Add an object to a `region`"
  def add_object(region, id, object) do
    GenServer.call(region, {:add_object, id, object})
  end

  @doc "Remove an object from `region`"
  def remove_object(region, id) do
    GenServer.call(region, {:remove_object, id})
  end

  @doc "Query around a `region` for a given `point` by `distance`"
  def query_around(region, point, distance) do
    GenServer.call(region, {:query_around, point, distance})
  end

  @doc "Query nearest locations from `point` limited by `limit`"
  def query_nearest(region, point, limit) do
    GenServer.call(region, {:query_nearest, point, limit})
  end

  @doc "Return all the available regions"
  def all do
    Supervisor.which_children(@region_sup)
    |> Enum.map(fn {name, pid, _, _} -> {name, pid} end)
  end

  def start_link(name, lat, lon) do
    GenServer.start_link(__MODULE__, [name, lat, lon])
  end

  # GenServer callbacks

  def init([name, lat, lon]) do
    table_opts =
      [:set,
       read_concurrency: true,
       write_concurrency: true]

    object_table = :ets.new(:"#{name}_objects", table_opts)
    geo_table = :ets.new(:"#{name}_geometries", table_opts)

    coverage = Point.new(lat, lon) |> SearchBox.new(@default_radius)
    zone = Zone.new(2)

    state =
      %{name: name, objects: object_table,
        geometries: geo_table, zone: zone,
        coverage: coverage}

    {:ok, state}
  end

  def handle_call(:list_objects, _from, state) do
    keys = :ets.foldl(&append_keys/2, [], state.objects)
    {:reply, {:ok, keys}, state}
  end
  def handle_call({:add_object, id, location}, _from, state) do
    object = %{id: id, location: location}
    {resp, new_state} =
      case :ets.insert_new(state.objects, {id, object}) do
        true ->
          {:ok, %{state| zone: Zone.add_point(state.zone, location)}}
        false ->
          {:already_added, state}
      end
    {:reply, resp, new_state}
  end
  def handle_call({:remove_object, id}, _from, state) do
    {resp, new_state} =
      case :ets.lookup(state.objects, id) do
        [] ->
          {:not_found, state}
        [{^id, obj}] ->
          :ets.delete(state.objects, id)
          {:ok, %{state| zone: Zone.delete_point(state.zone, obj.location)}}
      end
    {:reply, resp, new_state}
  end
  def handle_call({:query_around, search_point, distance}, _from, state) do
    location = Query.around(state.zone, search_point, distance)
    {:reply, {:ok, location}, state}
  end
  def handle_call({:query_nearest, search_point, limit}, _from, state) do
    location = Query.nearest(state.zone, search_point, limit)
    {:reply, {:ok, location}, state}
  end

  # Internal functions

  defp append_keys({key, _val}, acc), do: [key | acc]
end
