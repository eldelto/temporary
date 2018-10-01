defmodule TemporaryServerWeb.LayoutView do
  use TemporaryServerWeb, :view

  def version() do
    {:ok, version} = :application.get_key(:temporary_server, :vsn)
    version
  end
end
