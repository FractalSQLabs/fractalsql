#!/bin/bash
#
# postgresql-fractalsql packaging.
#
# Assumes ./build.sh ${ARCH} has already produced:
#   dist/${ARCH}/fractalsql_pg16.so
#   dist/${ARCH}/fractalsql_pg17.so
#   dist/${ARCH}/fractalsql_pg18.so
#
# Emits one .deb and one .rpm per (PG major, arch) pair into
# dist/packages/:
#   dist/packages/postgresql-16-fractalsql-amd64.deb
#   dist/packages/postgresql-16-fractalsql-amd64.rpm
#   dist/packages/postgresql-18-fractalsql-arm64.deb
#   ...
#
# Usage:
#   ./package.sh [amd64|arm64]     # default: amd64

set -euo pipefail

VERSION="1.0.0"
ITERATION="1"
DIST_DIR="dist/packages"
mkdir -p "${DIST_DIR}"

PKG_ARCH="${1:-amd64}"
case "${PKG_ARCH}" in
    amd64|arm64) ;;
    *)
        echo "unknown arch '${PKG_ARCH}' — expected amd64 or arm64" >&2
        exit 2
        ;;
esac

case "${PKG_ARCH}" in
    amd64) RPM_ARCH="x86_64" ;;
    arm64) RPM_ARCH="aarch64" ;;
esac

SRC_DIR="dist/${PKG_ARCH}"

for PG_VER in 16 17 18; do
    SO="${SRC_DIR}/fractalsql_pg${PG_VER}.so"
    if [ ! -f "${SO}" ]; then
        echo "missing ${SO} — run ./build.sh ${PKG_ARCH} first" >&2
        exit 1
    fi

    PKG_NAME="postgresql-${PG_VER}-fractalsql"
    DEB_OUT="${DIST_DIR}/${PKG_NAME}-${PKG_ARCH}.deb"
    RPM_OUT="${DIST_DIR}/${PKG_NAME}-${PKG_ARCH}.rpm"

    # Build a staging root that mirrors the on-disk layout of a PG-X
    # extension so fpm can just tar it up.
    STAGE="$(mktemp -d)"
    trap 'rm -rf "${STAGE}"' EXIT

    install -Dm0755 "${SO}" \
        "${STAGE}/usr/lib/postgresql/${PG_VER}/lib/fractalsql.so"
    install -Dm0644 fractalsql.control \
        "${STAGE}/usr/share/postgresql/${PG_VER}/extension/fractalsql.control"
    install -Dm0644 sql/fractalsql--1.0.sql \
        "${STAGE}/usr/share/postgresql/${PG_VER}/extension/fractalsql--1.0.sql"

    echo "------------------------------------------"
    echo "Packaging ${PKG_NAME} (${PKG_ARCH})"
    echo "------------------------------------------"

    fpm -s dir -t deb \
        -n "${PKG_NAME}" \
        -v "${VERSION}" \
        -a "${PKG_ARCH}" \
        --iteration "${ITERATION}" \
        --description "FractalSQL: Stochastic Fractal Search extension for PostgreSQL ${PG_VER}" \
        --depends "libc6 (>= 2.38)" \
        --depends "libluajit-5.1-2" \
        --depends "postgresql-${PG_VER}" \
        -C "${STAGE}" \
        -p "${DEB_OUT}" \
        usr

    fpm -s dir -t rpm \
        -n "${PKG_NAME}" \
        -v "${VERSION}" \
        -a "${RPM_ARCH}" \
        --iteration "${ITERATION}" \
        --description "FractalSQL: Stochastic Fractal Search extension for PostgreSQL ${PG_VER}" \
        --depends "luajit" \
        --depends "postgresql${PG_VER}-server" \
        -C "${STAGE}" \
        -p "${RPM_OUT}" \
        usr

    rm -rf "${STAGE}"
    trap - EXIT
done

echo
echo "Done. Packages in ${DIST_DIR}:"
ls -l "${DIST_DIR}"
