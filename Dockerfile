#===========
#Build Stage
#===========
FROM bitwalker/alpine-elixir:1.10.4 as build

#Copy the source folder into the Docker image
COPY . .

#Install dependencies and build Release
ENV MIX_ENV=prod

RUN apk update && \
    apk add -u musl musl-dev musl-utils nodejs-npm build-base

RUN rm -Rf _build && \
    mix deps.get && \
    mix compile && \
    cd assets && \
    npm install && \
    node ./node_modules/brunch/bin/brunch b -p && \
    cd .. && \
    mix phx.digest && \
    mix release

#Extract Release archive to /rel for copying in next stage
RUN APP_NAME="temporary_server" && \
    RELEASE_DIR=`ls -d _build/prod/rel/$APP_NAME/` && \
    mkdir /export && \
    mv $RELEASE_DIR "/export/" && \
    chown /export/bin/*

#================
#Deployment Stage
#================
FROM pentacent/alpine-erlang-base:latest

#Set environment variables and expose port
EXPOSE 4000
ENV REPLACE_OS_VARS=true \
    PORT=4000

#Copy and extract release file from the previous stage
COPY --from=build /export/ .

#Change user
USER default

#Set default entrypoint and command
ENTRYPOINT ["/opt/app/bin/temporary_server"]
CMD ["start"]
