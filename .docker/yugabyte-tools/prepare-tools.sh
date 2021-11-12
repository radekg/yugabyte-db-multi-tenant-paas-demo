#!/bin/bash

set -euo

patchelfpath=$(find /home -name patchelf)
if [ -z "${patchelfpath}" ]; then
    echo "ERROR: doesn't look like a YugabyteDB image"
    exit 1
fi

source_root=$(dirname $(dirname ${patchelfpath}))
TARGET_ROOT=${TARGET_ROOT:-/tools}

# copy YB binaries:
binaries=("cqlsh" "yb-admin" "yb-bulk_load" "yb-ctl" "yb-ts-cli")
for f in "${binaries[@]}"; do
  mkdir -p "${TARGET_ROOT}/bin"
  cp -v "${source_root}/bin/${f}" "${TARGET_ROOT}/bin/${f}"
done

# copy Postgres binaries:
binaries=("ysql_bench" "ysql_dump" "ysql_dumpall" "ysqlsh")
for f in "${binaries[@]}"; do
  mkdir -p "${TARGET_ROOT}/postgres/bin"
  cp -v "${source_root}/postgres/bin/${f}" "${TARGET_ROOT}/postgres/bin/${f}"
done

# copy YB libs:
for f in $(find ${source_root}/lib -name '*.so*'); do
  relative=$(echo $f | sed 's!'${source_root}'!!')
  full_target="${TARGET_ROOT}${relative}"
  mkdir -p $(dirname ${full_target})
  cp -v ${f} ${full_target}
done

# copy Postgres libs:
for f in $(find ${source_root}/postgres/lib -name 'libpq.so*'); do
  relative=$(echo $f | sed 's!'${source_root}'!!')
  full_target="${TARGET_ROOT}${relative}"
  mkdir -p $(dirname ${full_target})
  cp -v ${f} ${full_target}
done

# copy Linux Brew libs:
for f in $(find ${source_root}/linuxbrew -name '*.so*'); do
  relative=$(echo $f | sed 's!'${source_root}'!!')
  full_target="${TARGET_ROOT}${relative}"
  mkdir -p $(dirname ${full_target})
  cp -v ${f} ${full_target}
done