defmodule TemporaryServer.Storable do
  defmodule NotFoundError do
    defexception message: nil

    def exception(uuid) do
      %__MODULE__{message: "Entry with uuid '#{inspect(uuid)}' could not be found."}
    end
  end

  alias Chunker.DiscBased

  require Logger

  defstruct uuid: nil,
            name: nil,
            chunked_file: nil,
            create_date: nil

  @mnesia_name :file_storage
  @storage_path "file_storage"

  ## Public API ##
  def init_mnesia do
    mnesia_dir = Path.join(@storage_path, "mnesia") |> String.to_charlist()
    Application.put_env(:mnesia, :dir, mnesia_dir)

    schema_result = :mnesia.create_schema([node()])
    Logger.info("Creating Mnesia schema: #{inspect(schema_result)}")

    :ok = :mnesia.start()

    table_result =
      :mnesia.create_table(
        @mnesia_name,
        disc_copies: [node()],
        attributes: [:uuid, :create_date, :storable],
        type: :set
      )

    Logger.info("Creating Mnesia table: #{inspect(table_result)}")

    {:ok, @mnesia_name}
  end

  def new(uuid, name) when is_bitstring(uuid) and is_bitstring(name) do
    case fetch_entry(uuid) do
      {:error, %__MODULE__.NotFoundError{}} -> create_new_storable(uuid, name)
      result -> result
    end
  end

  def table_name, do: @mnesia_name

  def storage_path, do: @storage_path

  def store_entry(storable) do
    case :mnesia.transaction(fn ->
           :mnesia.write({
             @mnesia_name,
             storable.uuid,
             storable.create_date,
             storable
           })
         end) do
      {:atomic, :ok} -> {:ok, storable}

      {:aborted, {:no_exists, @mnesia_name}} ->
        {:error, __MODULE__.NotFoundError.exception("Table not found.")}

      err -> err
    end
  end

  def fetch_entry(uuid) when is_bitstring(uuid) do
    case :mnesia.transaction(fn ->
           :mnesia.read({@mnesia_name, uuid})
         end) do
      {:atomic, [{_, _, _, storable} | _]} ->
        {:ok, storable}

      {:atomic, []} ->
        {:error, __MODULE__.NotFoundError.exception(uuid)}

      {:aborted, {:no_exists, @mnesia_name}} ->
        {:error, __MODULE__.NotFoundError.exception(uuid)}

      err ->
        err
    end
  end

  def remove_entry(uuid) when is_bitstring(uuid) do
    case :mnesia.transaction(fn ->
           :mnesia.delete({@mnesia_name, uuid})
         end) do
      {:atomic, :ok} -> :ok
      err -> err
    end
  end

  ## Helper functions ##
  defp create_new_storable(uuid, name) do
    with storage_path <- path_from_uuid(uuid),
         {:ok, chunked_file} <- DiscBased.new(storage_path, 466_112),
         storable <- %__MODULE__{
           uuid: uuid,
           name: name,
           chunked_file: chunked_file,
           create_date: DateTime.utc_now() |> DateTime.to_unix()
         } do
      store_entry(storable)
    else
      err -> err
    end
  end

  defp path_from_uuid(uuid) when is_bitstring(uuid) do
    Path.join(@storage_path, uuid)
  end
end

defimpl Chunker.ChunkedFile, for: TemporaryServer.Storable do
  alias TemporaryServer.Storable

  def insert_chunk(chunked_file, data, index) do
    update_chunked_file(chunked_file, fn x ->
      Chunker.insert_chunk(x, data, index)
    end)
  end

  def commit(chunked_file) do
    update_storable(chunked_file, fn x -> Chunker.commit(x) end)
  end

  def get_chunk(chunked_file, index) do
    Chunker.get_chunk(chunked_file.chunked_file, index)
  end

  def length(chunked_file) do
    Chunker.length(chunked_file.chunked_file)
  end

  def writeable?(chunked_file) do
    Chunker.writeable?(chunked_file.chunked_file)
  end

  def close(chunked_file) do
    Chunker.close(chunked_file.chunked_file)
  end

  def closed?(chunked_file) do
    Chunker.closed?(chunked_file.chunked_file)
  end

  def remove_chunk(chunked_file, index) do
    update_chunked_file(chunked_file, fn x ->
      Chunker.remove_chunk(x, index)
    end)
  end

  def remove(chunked_file) do
    case Chunker.remove(chunked_file.chunked_file) do
      :ok -> Storable.remove_entry(chunked_file.uuid)
      err -> err
    end
  end

  ## Helper functions ##
  defp update_chunked_file(storable, callback) do
    case callback.(storable.chunked_file) do
      {:ok, _} -> {:ok, storable}
      err -> err
    end
  end

  defp update_storable(storable, callback) do
    case callback.(storable.chunked_file) do
      {:ok, chunked_file} ->
        Storable.store_entry(%Storable{storable | chunked_file: chunked_file})

      err ->
        err
    end
  end
end
