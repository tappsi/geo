defmodule Geo.Application do
  @moduledoc false

  use Application

  # API

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      supervisor(Geo.Region.Supervisor, [])
    ]

    opts = [strategy: :one_for_one, name: Geo.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
