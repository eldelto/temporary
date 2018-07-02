defmodule TemporaryServer.Storage do
  defstruct uuid: nil, 
            name: nil, 
            path: nil, 
            create_date: DateTime.utc_now(), 
            downloaded_chunks: []

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
end