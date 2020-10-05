#============
# Build Stage
#============
FROM bitwalker/alpine-elixir:1.10.4 as build

RUN apk update && \
    apk add -u musl musl-dev musl-utils nodejs-npm build-base

WORKDIR /app

# Copy the source folder into the Docker image
COPY . .

# Install dependencies and build Release
ENV MIX_ENV=prod

RUN rm -Rf _build && \
    mix deps.get && \
    mix compile && \
    cd assets && \
    npm install && \
    node ./node_modules/brunch/bin/brunch b -p && \
    cd .. && \
    mix phx.digest && \
    mix release && \
    chown -R default _build/

#=================
# Deployment Stage
#=================
FROM pentacent/alpine-erlang-base:latest

# Set environment variables and expose port
EXPOSE 4000
ENV REPLACE_OS_VARS=true \
    PORT=4000

# Change user
USER default

WORKDIR /app

# Copy release files from the previous stage
COPY --from=build /app/_build/prod/rel/temporary_server/ .

# Set default entrypoint and command
ENTRYPOINT ["/app/bin/temporary_server"]
CMD ["start"]
