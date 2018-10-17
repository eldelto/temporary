defmodule TemporaryServer.Storable.Cleanup do
  use GenServer

  alias TemporaryServer.Storable

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
    remove_old_files()
    # Reschedule once more
    schedule_work()

    {:noreply, state}
  end

  ## Helper functions ##
  defp schedule_work() do
    # Every 5 minutes
    Process.send_after(self(), :work, 5 * 60 * 1000)
  end

  defp remove_old_files do
    fetch_old_files()
    |> Enum.map(fn storable ->
      with :ok <- Chunker.remove(storable),
           :ok <- Chunker.close(storable) do
        Logger.info("Removed file with uuid '#{inspect(storable.uuid)}'.")
      else
        err ->
          Logger.error("Error while removing file with uuid '#{inspect(storable.uuid)}': 
            #{inspect(err)}")
      end
    end)

    Logger.info("Storable.Cleanup run finished.")
  end

  defp fetch_old_files do
    table = Storable.table_name()

    :mnesia.dirty_select(
      table,
      [
        {
          {table, :_, :"$2", :"$3"},
          [
            {:<, :"$2", three_days_ago()}
          ],
          [:"$3"]
        }
      ]
    )
  end

  defp three_days_ago do
    now =
      DateTime.utc_now()
      |> DateTime.to_unix()

    now - 3 * 24 * 60 * 60
  end
end
