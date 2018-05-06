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

  scope "/api", TemporaryServerWeb do
     pipe_through :api

     get "/test", FileController, :test
     post "/store/:binary", FileController, :store
     get "/info/:uuid", FileController, :info
     get "/fetch/:uuid", FileController, :fetch
  end
end
