defmodule TemporaryServerWeb.FileView do
  use TemporaryServerWeb, :view

  def render("test.json", _assigns) do
    %{test: "hello"}
  end

  def render("store.json", _assigns) do
    %{status: "OK"}
  end

  def render("fetch.json", _assigns) do
    %{
      timestamp: 1231231231,
      binary: "<this will be your base64 string"
    }
  end
end
