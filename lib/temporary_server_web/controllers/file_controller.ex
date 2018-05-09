defmodule TemporaryServerWeb.FileController do
  use TemporaryServerWeb, :controller

  def test(conn, _params) do
    json conn, %{test: "hello"}
  end

  def store(conn, %{"uuid" => uuid, "binary" => binary}) do
    create_date = DateTime.utc_now()
    
    case :ets.insert_new(:file_storage, {uuid, %{create_date: create_date, binary: binary}}) do
      true ->
        json conn, %{status: "OK"}
      false ->
        json conn, %{status: "ERROR", message: "File already exists."}
      _ ->
        json conn, %{status: "ERROR", message: "Error while storing file."}
    end
  end

  def store(conn, params) do
    json conn, %{status: "ERROR", message: "Field 'binary' is missing in JSON."}
  end

  def info(conn, params) do
    json conn, fetch_file(params["uuid"], fn file_attributes -> 
      %{
        status: "OK",
        uuid: file_attributes.uuid,
        create_date: file_attributes.create_date
      }
    end)
  end

  def fetch(conn, params) do
    json conn, fetch_file(params["uuid"], fn file_attributes -> 
      %{
        status: "OK",
        uuid: file_attributes.uuid,
        create_date: file_attributes.create_date,
        binary: file_attributes.binary
      }
    end)
  end

  defp fetch_file(uuid, json_builder) do
    with [{^uuid, file_attributes}] <- :ets.lookup(:file_storage, uuid) do
      json_builder.(Map.put(file_attributes, :uuid, uuid))
    else
      _ -> %{status: "ERROR", message: "File not found."}
    end
  end
end
