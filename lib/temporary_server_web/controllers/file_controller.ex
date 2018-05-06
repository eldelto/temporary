defmodule TemporaryServerWeb.FileController do
  use TemporaryServerWeb, :controller

  def test(conn, _params) do
    render conn, "test.json"
  end

  def store(conn, params) do
    render conn, "store.json", params
  end

  def fetch(conn, params) do
    render conn, "fetch.json", params
  end
end
