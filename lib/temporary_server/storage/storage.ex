defmodule TemporaryServer.Storage do
  use GenServer

  require Logger

  alias Chunker.ChunkedFile

  defstruct uuid: nil, 
            name: nil, 
            path: nil, 
            create_date: DateTime.utc_now(), 
            downloaded_chunks: []

  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, [name: __MODULE__] ++ opts)
  end

  def new(uuid, name) do
    GenServer.call(__MODULE__, {:new, uuid, name})
  end

  def append(uuid, data) do
    GenServer.call(__MODULE__, {:append, uuid, data})
  end

  def commit(uuid) do
    GenServer.call(__MODULE__, {:commit, uuid})
  end

  def get_chunk(uuid, index) do
    with  {:ok, storable} <- get(uuid),
          {:ok, chunked_file} <- chunked_file_from_storable(storable),
          false <- ChunkedFile.writeable?(chunked_file),
          {:ok, data} <- ChunkedFile.chunk(chunked_file, index),
          {:ok, storable} <- add_downloaded_chunk(storable, index) do
      {:ok, chunks} = ChunkedFile.chunks(chunked_file)
      if length(storable.downloaded_chunks) == length(chunks) do
        {:ok, _} = remove(storable)
        Logger.info("Removed #{inspect storable.uuid}")
      end      
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

  def init(:ok) do
    {:ok, %{}}
  end

  def handle_call({:new, uuid, name}, _from, state) do
    storage_path = path(uuid)
    with  {:ok, true} <- store(uuid, name, storage_path),
          {:ok, _} <- chunked_file_from_uuid(uuid) do
      {:reply, {:ok, nil}, state}
    else
      {:error, false} -> {:reply, {:error, "File already exists."}, state}
      _ -> {:reply, {:error, "Error while creating chunked file."}, state}
    end    
  end

  def handle_call({:append, uuid, data}, _from, state) do
    with  {:ok, storable} <- get(uuid),
          {:ok, chunked_file} <- chunked_file_from_storable(storable),
          {:ok, _} <- ChunkedFile.append_chunk(chunked_file, data) do
      {:reply, {:ok, nil}, state}
    else
      _ -> {:reply, {:error, "Error while appending chunk."}, state}
    end
  end

  def handle_call({:commit, uuid}, _from, state) do
    with  {:ok, storable} <- get(uuid),
          {:ok, chunked_file} <- chunked_file_from_storable(storable),
          {:ok, _} <- ChunkedFile.commit(chunked_file),
          {:ok, _} <- ChunkedFile.remove(chunked_file) do
      {:reply, {:ok, nil}, state}
    else
      _ -> {:reply, {:error, "Error while committing chunked file."}, state}
    end
  end

  defp store(uuid, name, path) do
    storable = %__MODULE__{uuid: uuid, name: name, path: path}
    case :ets.insert_new(:file_storage, {uuid, storable}) do
      true ->
        {:ok, true}
      false ->
        {:error, false}
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

  defp chunked_file_from_uuid(uuid) do
    storage_path = path(uuid)
    Chunker.new(storage_path)
  end

  defp chunked_file_from_storable(storable) do
    Chunker.new(storable.path, 1_864_216)
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
end