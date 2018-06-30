defmodule TemporaryServer.Storage do
  defstruct uuid: nil, name: nil, path: nil, create_date: DateTime.utc_now()

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
end