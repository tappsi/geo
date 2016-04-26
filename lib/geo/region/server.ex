defmodule Geo.Region.Server do
  @moduledoc false

  use GenServer

  alias Geo.Query
  alias Geo.Geometry.{Point, Zone, SearchBox}

  @transfer_timeout 60_000 # 60sec
  @default_radius   10_000 # 10km

  # GenServer callbacks

  def start_link(id, name, lat, lon) do
    GenServer.start_link(__MODULE__, [id, name, lat, lon])
  end

  def init([id, name, lat, lon]) do
    table_opts =
      [:set,
       read_concurrency: true,
       write_concurrency: true]

    object_table = :ets.new(:objects, table_opts)
    geo_table = :ets.new(:geometries, table_opts)

    coverage = Point.new(lat, lon) |> SearchBox.new(@default_radius)
    zone = Zone.new(2)

    state =
      %{id: id, name: name, objects: object_table,
        geometries: geo_table, zone: zone, coverage: coverage}

    {:ok, state}
  end

  ## Objects API

  def handle_call(:list_objects, _from, state) do
    keys =
      :ets.foldl(fn {key, _val}, acc ->
        [key | acc]
      end, [], state.objects)

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

  @doc false
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

  ## Geo API

  def handle_call({:query_around, search_point, distance}, _from, state) do
    location = Query.around(state.zone, search_point, distance)
    {:reply, {:ok, location}, state}
  end

  def handle_call({:query_nearest, search_point, limit}, _from, state) do
    location = Query.nearest(state.zone, search_point, limit)
    {:reply, {:ok, location}, state}
  end
end
