defmodule Geo.Region.Supervisor do
  @moduledoc false

  use Supervisor

  @name __MODULE__

  # API

  def start_link do
    Supervisor.start_link(__MODULE__, [], name: @name)
  end

  # Supervisor callbacks

  def init(_args) do
    child = worker(Geo.Region, [], restart: :transient)
    supervise([child], [strategy: :simple_one_for_one])
  end
end
