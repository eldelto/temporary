defmodule TemporaryServerWeb.ChunkerController do
  use TemporaryServerWeb, :controller

  require Logger

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
    with  {:ok, storable} <- Storage.get(uuid),
          {:ok, chunked_file} <- chunked_file_from_storable(storable),
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
    with  {:ok, storable} <- Storage.get(uuid),
          {:ok, chunked_file} <- chunked_file_from_storable(storable),
          {:ok, _} <- ChunkedFile.commit(chunked_file),
          {:ok, _} <- ChunkedFile.remove(chunked_file) do
      json conn, Message.success("Chunked file successfully committed.") 
    else
      _ -> json conn, Message.error("Error while committing chunked file.")
    end
  end

  def length(conn, %{"uuid" => uuid}) do
    with  {:ok, storable} <- Storage.get(uuid),
          {:ok, chunked_file} <- chunked_file_from_storable(storable),
          {:ok, chunks} <- ChunkedFile.chunks(chunked_file) do
      json conn, Message.success("Successfully fetched chunked file length.", 
                          %{"length" => length(chunks)})
    else
      _ -> json conn, Message.error("Error while fetching chunked file length.")
    end
  end

  def get_chunk(conn, %{"uuid" => uuid, "index" => index}) do
    with  {index, _} <- Integer.parse(index),
          {:ok, storable} <- Storage.get(uuid),
          {:ok, chunked_file} <- chunked_file_from_storable(storable),
          false <- ChunkedFile.writeable?(chunked_file),
          {:ok, data} <- ChunkedFile.chunk(chunked_file, index),
          {:ok, storable} <- Storage.add_downloaded_chunk(storable, index) do
      {:ok, chunks} = ChunkedFile.chunks(chunked_file)
      if length(storable.downloaded_chunks) == length(chunks) do
        {:ok, _} = remove_file_entry(storable, chunked_file)
        Logger.info("Removed #{inspect storable.uuid}")
      end
      json conn, Message.success("Successfully fetched chunk.", 
                          %{"data" => data})
    else
      true -> json conn, Message.error("Chunked file is not committed yet.")
      _ -> json conn, Message.error("Error while fetching chunk.")
    end
  end

  defp chunked_file_from_uuid(uuid) do
    storage_path = Storage.path(uuid)
    Chunker.new(storage_path)
  end

  defp chunked_file_from_storable(storable) do
    Chunker.new(storable.path)
  end

  defp remove_file_entry(storable, chunked_file) do
    path = ChunkedFile.path(chunked_file)
    
    case File.rm(path) do      
      :ok -> Storage.remove(storable)    
      err -> err
    end
  end
end