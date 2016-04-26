defmodule Geo.Region.Supervisor do
  @moduledoc false

  use Supervisor

  # API

  def worker(region_args, region_id) do
    worker(Geo.Region.Server, region_args, id: region_id)
  end

  # Supervisor callbacks

  def start_link do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_args) do
    opts = [strategy: :one_for_one]
    supervise([], opts)
  end
end
