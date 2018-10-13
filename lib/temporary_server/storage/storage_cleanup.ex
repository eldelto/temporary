defmodule TemporaryServer.Storage.Cleanup do
  use GenServer

  alias TemporaryServer.Storage

  require Logger

  ## Client ##
  def start_link do
    GenServer.start_link(__MODULE__, [])
  end

  ## Server ##
  def init(state) do
    # Schedule work to be performed at some point
    schedule_work()
    {:ok, state}
  end

  def handle_info(:work, state) do
    remove_old_files(:file_storage)
    # Reschedule once more
    schedule_work()

    {:noreply, state}
  end

  ## Helper functions ##
  defp schedule_work() do
    # Every 5 minutes
    Process.send_after(self(), :work, 5 * 60 * 1000)
  end

  defp remove_old_files(table) do
    now = DateTime.utc_now()
    |> DateTime.to_unix()

    :ets.foldl(
      fn item, _ ->
        {key, storable = %Storage{}} = item

        if DateTime.to_unix(storable.create_date) + 3 * 24 * 60 * 60 < now do
          Storage.remove(storable)
        end
      end,
      [],
      table
    )

    Logger.debug("Storage.Cleanup finished run.")
    {:ok, nil}
  end

  defp older_than_three_days?(date_time) do
    now = DateTime.utc_now()
    |> DateTime.to_unix()
    timestamp = DateTime.to_unix(date_time)

    timestamp + 3 * 24 * 60 * 60 < now
  end
end
