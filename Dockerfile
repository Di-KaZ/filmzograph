# Specify the Dart SDK base image version using dart:<version> (ex: dart:2.12)
FROM dart:stable AS build

# Resolve app dependencies.
WORKDIR /app
COPY pubspec.* ./

# RUN cat /etc/*-release

RUN apt-get update -y && apt-get install libsqlite3-dev -y
RUN dart pub get
RUN dart pub global activate dart_frog_cli

# Copy app source code and AOT compile it.
COPY . .

# Ensure packages are still up-to-date if anything has changed
RUN dart pub get --offline
RUN dart_frog build

# Start server.
EXPOSE 8080
# CMD ["/app/bin/server"]
CMD ["dart", "build/bin/server.dart"]
