defmodule TemporaryServer.Message do
    def generic(status, message, payload \\ nil) do
        %{
            status: status,
            message: message,
            payload: payload
        }
    end

    def success(message, payload \\ nil), do: generic("OK", message, payload)

    def error(message, payload \\ nil), do: generic("ERROR", message, payload)
end