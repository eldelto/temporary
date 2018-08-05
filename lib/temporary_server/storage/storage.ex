defmodule TemporaryServer.Storage do
  require Logger

  alias Chunker.ChunkedFile

  defstruct uuid: nil, 
            name: nil, 
            path: nil,
            chunked_file: nil,
            create_date: DateTime.utc_now(), 
            downloaded_chunks: []

  def new(uuid, name) do
    storage_path = path(uuid)
    case store(uuid, name, storage_path) do
      {:ok, true} -> {:ok, true}
      {:error, false} -> {:error, "File already exists."}
      _ -> {:error, "Error while creating chunked file."}
    end
  end

  def append(uuid, data) do
    with  {:ok, storable} <- get(uuid),
          {:ok, chunked_file} <- chunked_file_from_storable(storable) do
      ChunkedFile.append_chunk(chunked_file, data)      
    else
      err -> err
    end
  end

  def commit(uuid) do
    with  {:ok, storable} <- get(uuid),
          {:ok, chunked_file} <- chunked_file_from_storable(storable),
          {:ok, _} <- ChunkedFile.commit(chunked_file) do
      ChunkedFile.remove(chunked_file)      
    else
      _ -> {:error, "Error while committing chunked file."}
    end
  end

  def get_chunk(uuid, index) do
    with  {:ok, storable} <- get(uuid),
          {:ok, chunked_file} <- chunked_file_from_storable(storable),
          false <- ChunkedFile.writeable?(chunked_file),
          {:ok, data} <- ChunkedFile.chunk(chunked_file, index),
          {:ok, storable} <- add_downloaded_chunk(storable, index) do
      {:ok, chunks} = ChunkedFile.chunks(chunked_file)
      #if length(storable.downloaded_chunks) == length(chunks) do
      #  {:ok, _} = remove(storable)
      #  Logger.info("Removed #{inspect storable.uuid}")
      #end      
      {:ok, data}
    else
      err -> err
    end
  end

  def path() do
    "file_storage"
  end

  def path(path) do
    Path.join("file_storage", path)
  end

  def get(uuid) do
    case :ets.lookup(:file_storage, uuid) do
      [{^uuid, storable = %__MODULE__{}}] -> {:ok, storable}
      _ -> {:error, "ETS entry not found."}
    end 
  end

  def chunk_count(uuid) do
    with  {:ok, storable} <- get(uuid),
          {:ok, chunked_file} <- chunked_file_from_storable(storable),
          {:ok, chunks} <- ChunkedFile.chunks(chunked_file) do
      {:ok, length(chunks)}
    else
      err -> err
    end
  end

  def remove(%__MODULE__{uuid: uuid}) do
    remove(uuid)
  end

  def remove(uuid) do
    with {:ok, storable} <- get(uuid),
        {:ok, chunked_file} <- chunked_file_from_storable(storable),
        true <- :ets.delete(:file_storage, uuid) do
      remove_chunked_file(chunked_file)
    else
      err -> err
    end
  end

  ## Helper functions ##
  defp store(uuid, name, path) do
    with {:ok, chunked_file} <- new_chunked_file(path),
         storable <- %__MODULE__{uuid: uuid, name: name, 
                                path: path, chunked_file: chunked_file},
         true <- :ets.insert_new(:file_storage, {uuid, storable}) do
      {:ok, true}
    else
      false -> {:error, false}
      err -> err      
    end    
  end

  defp add_downloaded_chunk(storable, index) do
    with  false <- Enum.any?(storable.downloaded_chunks, &(&1 == index)),
          downloaded_chunks <- [index] ++ storable.downloaded_chunks,
          storable <- %__MODULE__{storable | downloaded_chunks: downloaded_chunks},
          true <- :ets.insert(:file_storage, {storable.uuid, storable}) do
      {:ok, storable}
    else
      true -> {:ok, storable}
      false -> {:error, "Could not insert data into ETS."}
      err -> err
    end
  end

  defp chunked_file_from_storable(storable) do
    if ChunkedFile.closed?(storable.chunked_file) do
      new_chunked_file(storable.path)
    else
      {:ok, storable.chunked_file}
    end
    
  end

  defp remove_chunked_file(chunked_file) do
    if ChunkedFile.writeable?(chunked_file) do
      ChunkedFile.remove(chunked_file)
    end

    path = ChunkedFile.path(chunked_file)    
    case File.rm(path) do      
      :ok -> {:ok, nil}  
      err -> err
    end
  end

  defp new_chunked_file(path) do
    Chunker.new(path, 1_864_216)
  end
end