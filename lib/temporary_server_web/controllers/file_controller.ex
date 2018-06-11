defmodule TemporaryServerWeb.FileController do
  use TemporaryServerWeb, :controller

  alias TemporaryServer.Message
  alias TemporaryServer.Storable

  def test(conn, _params) do
    json conn, %{test: "hello"}
  end

  def store(conn, %{
      "uuid" => uuid, 
      "base64Data" => base64Data,
      "name" => name
      }) do
    create_date = DateTime.utc_now()
    
    case :ets.insert_new(:file_storage, {uuid, %{
        create_date: create_date, 
        base64Data: base64Data, 
        name: name
      }}) do
      true ->
        json conn, Message.success("File successfully stored.")
      false ->
        json conn, Message.error("File already exists.")
      _ ->
        json conn, Message.error("Error while storing file")
    end
  end

  def store(conn, _params) do
    json conn, Message.error("Field 'base64Data' is missing in JSON.")
  end

  def info(conn, params) do
    json conn, fetch_file(params["uuid"], fn file_attributes -> 
      file = %Storable{
        uuid: file_attributes.uuid,
        create_date: file_attributes.create_date
      }

      Message.success("File successfully fetched.", file)
    end)
  end

  def fetch(conn, params) do
    json conn, fetch_file(params["uuid"], fn file_attributes -> 
      file = %Storable{
        uuid: file_attributes.uuid,
        create_date: file_attributes.create_date,
        base64Data: file_attributes.base64Data,
        name: file_attributes.name
      }

      Message.success("File successfully fetched.", file)
    end)
  end

  defp fetch_file(uuid, json_builder) do
    with [{^uuid, file_attributes}] <- :ets.lookup(:file_storage, uuid) do
      json_builder.(Map.put(file_attributes, :uuid, uuid))
    else
      _ -> Message.error("File not found.")
    end
  end
end
