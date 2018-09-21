defmodule TemporaryServerWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :temporary_server

  alias TemporaryServer.Storage

  socket "/socket", TemporaryServerWeb.UserSocket

  # Serve at "/" the static files from "priv/static" directory.
  #
  # You should set gzip to true if you are running phoenix.digest
  # when deploying your static files in production.
  plug Plug.Static,
    at: "/", from: :temporary_server, gzip: Application.get_env(:temporary_server, __MODULE__)[:gzip] || false,
    only: ~w(css fonts images js favicon.ico robots.txt)

  # Code reloading can be explicitly enabled under the
  # :code_reloader configuration of your endpoint.
  if code_reloading? do
    socket "/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket
    plug Phoenix.LiveReloader
    plug Phoenix.CodeReloader
  end

  plug Plug.RequestId
  plug Plug.Logger

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Poison,
    length: 100_000_000

  plug Plug.MethodOverride
  plug Plug.Head

  # The session will be stored in the cookie and signed,
  # this means its contents can be read but not tampered with.
  # Set :encryption_salt if you would also like to encrypt it.
  plug Plug.Session,
    store: :cookie,
    key: "_temporary_server_key",
    signing_salt: "ikvUTuWX"

  plug TemporaryServerWeb.Router

  @doc """
  Callback invoked for dynamically configuring the endpoint.

  It receives the endpoint configuration and checks if
  configuration should be loaded from the system environment.
  """
  def init(_key, config) do
    create_ets()
    create_storage_dir()
    clear_file_storage()

    if config[:load_from_system_env] do
      port = System.get_env("PORT") || raise "expected the PORT environment variable to be set"
      {:ok, Keyword.put(config, :http, [:inet6, port: port])}
    else
      {:ok, config}
    end
  end

  defp create_ets() do
    :ets.new(:file_storage, [:set, :public, :named_table])
  end

  defp create_storage_dir do
    File.mkdir(Storage.path())
  end

  defp clear_file_storage() do
    :os.cmd(to_charlist("rm -rf " <> Storage.path("*")))
  end
end
