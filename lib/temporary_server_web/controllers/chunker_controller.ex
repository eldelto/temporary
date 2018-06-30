defmodule TemporaryServerWeb.ChunkerController do
  use TemporaryServerWeb, :controller

  alias TemporaryServer.Message
  alias TemporaryServer.Storage
  alias Chunker.ChunkedFile

  # TODO: proper error handling for different failures.
  
  def new(conn, %{"uuid" => uuid,
                  "name" => name}) do
    storage_path = Storage.path(uuid)
    with  {:ok, true} <- Storage.store(uuid, name, storage_path),
          {:ok, _} <- chunked_file_from_uuid(uuid) do
      json conn, Message.success("New chunked file successfully created.")
    else
      {:error, false} -> json conn, Message.error("File already exists.")
      _ -> json conn, Message.error("Error while creating chunked file.")
    end
  end

  def new(conn, _) do
    json conn, Message.error("Required attributes are missing.")
  end

  def append(conn, %{
    "uuid" => uuid, 
    "base64Data" => base_64_data
    }) do
    with  {:ok, chunked_file} <- chunked_file_from_uuid(uuid),
          {:ok, _} <- ChunkedFile.append_chunk(chunked_file, base_64_data) do
      json conn, Message.success("Chunk successfully appended.") 
    else
      _ -> json conn, Message.error("Error while appending chunk.")
    end
  end

  def append(conn, _) do
    json conn, Message.error("Required attributes are missing.")
  end

  def commit(conn, %{"uuid" => uuid}) do
    with  {:ok, chunked_file} <- chunked_file_from_uuid(uuid),
          {:ok, _} <- ChunkedFile.commit(chunked_file),
          {:ok, _} <- ChunkedFile.remove(chunked_file) do
      json conn, Message.success("Chunked file successfully committed.") 
    else
      _ -> json conn, Message.error("Error while committing chunked file.")
    end
  end


  defp chunked_file_from_uuid(uuid) do
    storage_path = Storage.path(uuid)
    Chunker.new(storage_path)
  end
end