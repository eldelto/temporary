defmodule TemporaryServerWeb.ChunkerController do
  use TemporaryServerWeb, :controller

  alias TemporaryServer.Message
  alias TemporaryServer.Storable

  # TODO: proper error handling for different failures.

  def new(conn, %{"uuid" => uuid, "name" => name}) do
    case Storable.new(uuid, name) do
      {:ok, _} -> json(conn, Message.success("New chunked file successfully created."))
      {:error, msg} -> json(conn, Message.error(msg))
    end
  end

  def new(conn, _) do
    json(conn, Message.error("Required attributes are missing."))
  end

  def append(conn, %{
        "uuid" => uuid,
        "base64Data" => base_64_data
      }) do
    with {:ok, storable} <- Storable.fetch_entry(uuid),
         {:ok, _} <- Chunker.append_chunk(storable, base_64_data) do
      json(conn, Message.success("Chunk successfully appended."))
    else
      {:error, msg} -> json(conn, Message.error(msg))
    end
  end

  def append(conn, _) do
    json(conn, Message.error("Required attributes are missing."))
  end

  def commit(conn, %{"uuid" => uuid}) do
    with {:ok, storable} <- Storable.fetch_entry(uuid),
         {:ok, _} <- Chunker.commit(storable) do
      json(conn, Message.success("Chunked file successfully committed."))
    else
      {:error, msg} -> json(conn, Message.error(msg))
    end
  end

  def name(conn, %{"uuid" => uuid}) do
    case Storable.fetch_entry(uuid) do
      {:ok, storable} ->
        json(
          conn,
          Message.success(
            "Successfully fetched name.",
            %{"name" => storable.name}
          )
        )

      {:error, msg} ->
        json(conn, Message.error(msg))
    end
  end

  def length(conn, %{"uuid" => uuid}) do
    with {:ok, storable} <- Storable.fetch_entry(uuid),
         {:ok, length} <- Chunker.length(storable) do
      json(
        conn,
        Message.success(
          "Successfully fetched chunked file length.",
          %{"length" => length}
        )
      )
    else
      {:error, msg} -> json(conn, Message.error(msg))
    end
  end

  def get_chunk(conn, %{"uuid" => uuid, "index" => index}) do
    with {index, _} <- Integer.parse(index),
         {:ok, storable} <- Storable.fetch_entry(uuid),
         {:ok, data} <- Chunker.get_chunk(storable, index) do
      json(
        conn,
        Message.success(
          "Successfully fetched chunk.",
          %{"data" => data}
        )
      )
    else
      true -> json(conn, Message.error("Chunked file is not committed yet."))
      {:error, msg} -> json(conn, Message.error(msg))
      :error -> json(conn, Message.error("Internal error."))
    end
  end
end
