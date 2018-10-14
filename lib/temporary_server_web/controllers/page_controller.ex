defmodule TemporaryServerWeb.PageController do
  use TemporaryServerWeb, :controller

  require Logger

  alias TemporaryServer.Storable

  def index(conn, _params) do
    render(conn, "index.html")
  end

  def download(conn, %{"uuid" => uuid}) do
    case Storable.fetch_entry(uuid) do
      {:ok, storable} ->
        timestamp =
          storable.create_date
          |> timePlusDays(3)
          |> Kernel.*(1000)

        render(conn, "download.html",
          filename: storable.name,
          timestamp: timestamp
        )

      {:error, message} ->
        Logger.error(message)
        render(conn, "download_error.html", uuid: uuid)
    end
  end

  defp timePlusDays(time, days) do
    time + 60 * 60 * 24 * days
  end
end
