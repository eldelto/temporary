defmodule TemporaryServer.Storage do
  use GenServer

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
    GenServer.call(__MODULE__, {:get_chunk, uuid, index})
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
          {:ok, _} <- ChunkedFile.append_chunk(chunked_file, "chunk:" <> data) do
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


  def path(path) do
    Path.join("file_storage", path)
  end

  def store(uuid, name, path) do
    storable = %__MODULE__{uuid: uuid, name: name, path: path}
    case :ets.insert_new(:file_storage, {uuid, storable}) do
      true ->
        {:ok, true}
      false ->
        {:error, false}
      err -> err      
    end
  end

  def get(uuid) do
    case :ets.lookup(:file_storage, uuid) do
      [{^uuid, storable = %__MODULE__{}}] -> {:ok, storable}
      _ -> {:error, "ETS entry not found."}
    end 
  end

  def add_downloaded_chunk(storable, index) do
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

  def remove(%__MODULE__{uuid: uuid}) do
    remove(uuid)
  end

  def remove(uuid) do
    case :ets.delete(:file_storage, uuid) do
      true -> {:ok, nil}
      _ -> {:error, "Could not remove data from ETS."}
    end
  end

  defp chunked_file_from_uuid(uuid) do
    storage_path = path(uuid)
    Chunker.new(storage_path)
  end

  defp chunked_file_from_storable(storable) do
    Chunker.new(storable.path)
  end

  defp remove_file_entry(storable, chunked_file) do
    path = ChunkedFile.path(chunked_file)
    
    case File.rm(path) do      
      :ok -> remove(storable)    
      err -> err
    end
  end
end