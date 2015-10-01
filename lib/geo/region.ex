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
  @region_sup Geo.Region.Supervisor

  # API

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
    |> Enum.map fn {name, pid, _, _} ->
      {name, pid}
    end
  end

  @doc "Create a new region"
  def new(name, lat, lon) do
    region_id    = :crypto.hash(:md5, name) |> Base.encode64
    region_args  = [region_id, name, lat, lon]
    region_specs = @region_sup.worker(region_args, region_id)

    Supervisor.start_child(@region_sup, region_specs)
  end

  @doc "Shutdown the region identified by `id`"
  def shutdown(id) do
    Supervisor.terminate_child(@region_sup, id)
    Supervisor.delete_child(@region_sup, id)
  end
end
