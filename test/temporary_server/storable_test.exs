defmodule TemporaryServer.StorableTest do
  use ExUnit.Case

  alias Chunker.AlreadyClosedError
  alias Chunker.InvalidIndexError
  alias TemporaryServer.Storable

  @uuid "123"
  @file_name "file1"

  setup_all do
    {:ok, _} = Storable.init_mnesia()
    :ok
  end

  setup do
    on_exit(fn ->
      :mnesia.transaction(fn -> :mnesia.delete({Storable.table_name(), @uuid}) end)
      :os.cmd(to_charlist("rm " <> file_path()))
      :os.cmd(to_charlist("rm -rf " <> chunked_file_path()))
    end)
  end

  test "new ChunkedFile" do
    assert %Storable{} = new_chunked_file()
  end

  test "appending chunks" do
    chunked_file = new_chunked_file()

    assert {:ok, _} = Chunker.append_chunk(chunked_file, "test")
    assert {:ok, _} = Chunker.append_chunk(chunked_file, "test")

    assert {:ok, _} = File.stat(chunked_file_path())
  end

  test "committing ChunkedFile" do
    chunked_file = new_chunked_file()

    {:ok, _} = Chunker.append_chunk(chunked_file, "hello ")
    {:ok, _} = Chunker.append_chunk(chunked_file, "world")

    assert {:ok, %Storable{}} = Chunker.commit(chunked_file)
    assert {:ok, "hello world"} = File.read(file_path())
    assert {:error, :enoent} = File.lstat(chunked_file_path())

    {:error, _} = Chunker.append_chunk(chunked_file, "hello ")
  end

  @tag :skip
  test "inserting chunk" do
  end

  test "getting chunk" do
    chunked_file = new_chunked_file()

    {:ok, _} = Chunker.append_chunk(chunked_file, "hello")
    {:ok, _} = Chunker.append_chunk(chunked_file, "world")

    assert {:ok, "world"} = Chunker.chunk(chunked_file, 1)
    assert {:error, %InvalidIndexError{}} = Chunker.chunk(chunked_file, 100)
  end

  test "getting chunk length" do
    chunked_file = new_chunked_file()

    {:ok, _} = Chunker.append_chunk(chunked_file, "hello")
    {:ok, _} = Chunker.append_chunk(chunked_file, "world")

    assert {:ok, 2} = Chunker.length(chunked_file)
  end

  @tag :skip
  test "removing chunk" do
  end

  test "writeable?" do
    chunked_file = new_chunked_file()
    assert true === Chunker.writeable?(chunked_file)
  end

  test "removing ChunkedFile" do
    chunked_file = new_chunked_file()

    assert :ok = Chunker.remove(chunked_file)
    assert {:error, :enoent} = File.stat(chunked_file_path())

    assert {:atomic, []} =
             :mnesia.transaction(fn -> :mnesia.read(Storable.table_name(), @uuid) end)
  end

  test "closing ChunkedFile" do
    chunked_file = new_chunked_file()

    assert :ok = Chunker.close(chunked_file)
    assert {:error, %AlreadyClosedError{}} = Chunker.append_chunk(chunked_file, "hello")
  end

  test "closed?" do
    chunked_file = new_chunked_file()

    assert false === Chunker.closed?(chunked_file)

    :ok = Chunker.close(chunked_file)
    assert true === Chunker.closed?(chunked_file)
  end

  defp new_chunked_file do
    {:ok, chunked_file} = Storable.new(@uuid, @file_name)
    chunked_file
  end

  defp file_path do
    Path.join(Storable.storage_path(), @uuid)
  end

  defp chunked_file_path do
    file_path() <> ".chunked"
  end
end
