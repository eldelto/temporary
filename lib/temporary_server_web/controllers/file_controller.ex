defmodule TemporaryServerWeb.FileController do
  use TemporaryServerWeb, :controller

  def test(conn, _params) do
    json conn, %{test: "hello"}
  end

  def store(conn, params) do
    key = params["uuid"]
    binary = params["binary"]
    create_date = :os.system_time(:millisecond)
    
    case :ets.insert_new(:file_storage, {key, %{create_date: create_date, binary: binary}}) do
      true ->
        json conn, %{status: "OK"}
      false ->
        json conn, %{status: "ERROR", message: "File already exists."}
      _ ->
        json conn, %{status: "ERROR", message: "Error while storing file."}
    end
  end

  def info(conn, params) do
    uuid = params["uuid"]
    
    with [{^uuid, %{binary: _, create_date: create_date}}] <- :ets.lookup(:file_storage, uuid) do
      json conn, %{
        status: "OK",
        uuid: uuid,
        create_date: create_date
      }
    else
      _ -> json conn, %{status: "ERROR", message: "File not found."}
    end
  end

  def fetch(conn, params) do
    json conn, %{binary: "<this will be your base64 string>"}
  end
end
