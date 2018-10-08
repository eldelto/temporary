defmodule TemporaryServerWeb.Router do
  use TemporaryServerWeb, :router

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_flash)
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
  end

  pipeline :api do
    plug(:accepts, ["json"])
  end

  scope "/", TemporaryServerWeb do
    # Use the default browser stack
    pipe_through(:browser)

    get("/", PageController, :index)
    get("/download", PageController, :download)
  end

  scope "/api/chunker", TemporaryServerWeb do
    post("/new/:uuid", ChunkerController, :new)
    post("/append/:uuid", ChunkerController, :append)
    post("/commit/:uuid", ChunkerController, :commit)

    get("/name/:uuid", ChunkerController, :name)
    get("/length/:uuid", ChunkerController, :length)
    get("/chunk/:index/:uuid", ChunkerController, :get_chunk)
  end
end
