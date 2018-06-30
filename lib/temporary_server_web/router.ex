defmodule TemporaryServerWeb.Router do
  use TemporaryServerWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", TemporaryServerWeb do
    pipe_through :browser # Use the default browser stack

    get "/", PageController, :index
  end

  scope "/api/file", TemporaryServerWeb do
     pipe_through :api

     get "/test", FileController, :test
     post "/store/:uuid", FileController, :store
     get "/info/:uuid", FileController, :info
     get "/fetch/:uuid", FileController, :fetch
  end

  scope "/api/chunker", TemporaryServerWeb do    
    post "/new/:uuid", ChunkerController, :new
    post "/append/:uuid", ChunkerController, :append
    post "/commit/:uuid", ChunkerController, :commit
  end
end
