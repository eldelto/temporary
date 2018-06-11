defmodule TemporaryServer.Storable do
    defstruct name: "", uuid: "", base64Data: "", create_date: DateTime.utc_now()

    # def store_chunk(uuid, chunk_nr, data)
    # def fetch(uuid)
end