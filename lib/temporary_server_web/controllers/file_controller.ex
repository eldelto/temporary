defmodule TemporaryServerWeb.FileController do
  use TemporaryServerWeb, :controller

  def test(conn, _params) do
    json conn, %{test: "hello"}
  end

  def store(conn, params) do
    json conn, %{status: "OK"}
  end

  def info(conn, params) do
    json conn, %{
                  uuid: params["uuid"],
                  timestamp: 1231231231
                }
  end

  def fetch(conn, params) do
    json conn, %{binary: "<this will be your base64 string>"}
  end
end
