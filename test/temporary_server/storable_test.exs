defmodule TemporaryServer.StorableTest do
  use ExUnit.Case

  alias Chunker.AlreadyCommittedError
  alias Chunker.InvalidIndexError
  alias TemporaryServer.Storable

  @uuid "123"
  @file_name "file1"

  setup do
    :os.cmd(to_charlist("rm -rf " <> file_path() <> "/*"))
    :os.cmd(to_charlist("rm " <> chunked_file_path()))

    {:ok, _} = Storable.init_mnesia()
    :mnesia.delete_table(Storable.table_name())
    {:ok, _} = Storable.init_mnesia()

    :ok
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

  @tag :skip
  test "getting chunk" do
    chunked_file = new_chunked_file()

    {:ok, _} = Chunker.append_chunk(chunked_file, "hello")
    {:ok, _} = Chunker.append_chunk(chunked_file, "world")

    assert {:ok, "world"} = Chunker.chunk(chunked_file, 1)
    assert {:error, %InvalidIndexError{}} = Chunker.chunk(chunked_file, 100)
  end

  @tag :skip
  test "getting chunk length" do
    chunked_file = new_chunked_file()

    {:ok, _} = Chunker.append_chunk(chunked_file, "hello")
    {:ok, _} = Chunker.append_chunk(chunked_file, "world")

    assert {:ok, 2} = Chunker.length(chunked_file)
  end

  @tag :skip
  test "removing chunk" do
  end

  @tag :skip
  test "writeable?" do
    chunked_file = new_chunked_file()
    assert true === Chunker.writeable?(chunked_file)
  end

  @tag :skip
  test "removing ChunkedFile" do
    chunked_file = new_chunked_file()

    assert :ok = Chunker.remove(chunked_file)
    # assert {:error, :enoent} = File.stat(@writeable_file_path)
  end

  @tag :skip
  test "closing ChunkedFile" do
    chunked_file = new_chunked_file()

    assert :ok = Chunker.close(chunked_file)
    assert {:error, %AlreadyCommittedError{}} = Chunker.append_chunk(chunked_file, "hello")
  end

  @tag :skip
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
    Path.join(Storable.storage_path(), @uuid);
  end

  defp chunked_file_path do
    file_path() <> ".chunked"
  end
end
