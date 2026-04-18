# syntax=docker/dockerfile:1.7
#
# postgresql-fractalsql Factory build.
#
# Unlike MySQL UDFs, Postgres extensions hard-depend on PG_MODULE_MAGIC
# which is stamped with the server major version; a .so compiled for
# PG 16 will refuse to load under PG 17/18. So we build three distinct
# .so files, one per major, each against the matching
# postgresql-server-dev-${VER} headers from the official
# postgres:${VER}-bookworm images.
#
# Output (collected in the final `export` stage, emitted to the host
# via `docker buildx --output type=local,dest=...`):
#   /fractalsql_pg16.so
#   /fractalsql_pg17.so
#   /fractalsql_pg18.so
#
# Usage:
#   DOCKER_BUILDKIT=1 docker buildx build \
#     --platform linux/amd64 \
#     --target export \
#     --output type=local,dest=./dist/amd64 \
#     -f docker/Dockerfile .
#
# build.sh drives this for amd64 and arm64 in turn.

# ---------------------------------------------------------------------
# Shared bits — installed into each per-version stage below.
# ---------------------------------------------------------------------
#
# Each build stage starts from `postgres:${VER}-bookworm` so the
# installed pg_config and server-dev headers match the ABI of the
# target server. `postgresql-server-dev-${VER}` is installable from the
# PGDG repo already present in the official image.

# ---------------------------------------------------------------------
# Stage: PG 16 builder
# ---------------------------------------------------------------------
FROM postgres:16-bookworm AS build-pg16
USER root
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
        build-essential \
        libluajit-5.1-dev \
        postgresql-server-dev-16 \
        pkg-config \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /build
COPY Makefile            /build/Makefile
COPY fractalsql.control  /build/fractalsql.control
COPY src/                /build/src/
COPY include/            /build/include/
COPY sql/                /build/sql/

RUN make clean \
 && make PG_CONFIG=/usr/lib/postgresql/16/bin/pg_config \
 && cp fractalsql.so /fractalsql_pg16.so

# ---------------------------------------------------------------------
# Stage: PG 17 builder
# ---------------------------------------------------------------------
FROM postgres:17-bookworm AS build-pg17
USER root
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
        build-essential \
        libluajit-5.1-dev \
        postgresql-server-dev-17 \
        pkg-config \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /build
COPY Makefile            /build/Makefile
COPY fractalsql.control  /build/fractalsql.control
COPY src/                /build/src/
COPY include/            /build/include/
COPY sql/                /build/sql/

RUN make clean \
 && make PG_CONFIG=/usr/lib/postgresql/17/bin/pg_config \
 && cp fractalsql.so /fractalsql_pg17.so

# ---------------------------------------------------------------------
# Stage: PG 18 builder
# ---------------------------------------------------------------------
FROM postgres:18-bookworm AS build-pg18
USER root
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
        build-essential \
        libluajit-5.1-dev \
        postgresql-server-dev-18 \
        pkg-config \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /build
COPY Makefile            /build/Makefile
COPY fractalsql.control  /build/fractalsql.control
COPY src/                /build/src/
COPY include/            /build/include/
COPY sql/                /build/sql/

RUN make clean \
 && make PG_CONFIG=/usr/lib/postgresql/18/bin/pg_config \
 && cp fractalsql.so /fractalsql_pg18.so

# ---------------------------------------------------------------------
# Final export stage — scratch so buildx --output=local drops just the
# three per-version .so files onto the host.
# ---------------------------------------------------------------------
FROM scratch AS export
COPY --from=build-pg16 /fractalsql_pg16.so /fractalsql_pg16.so
COPY --from=build-pg17 /fractalsql_pg17.so /fractalsql_pg17.so
COPY --from=build-pg18 /fractalsql_pg18.so /fractalsql_pg18.so
