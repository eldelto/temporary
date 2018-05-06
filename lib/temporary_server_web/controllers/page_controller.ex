defmodule TemporaryServerWeb.PageController do
  use TemporaryServerWeb, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end
end
