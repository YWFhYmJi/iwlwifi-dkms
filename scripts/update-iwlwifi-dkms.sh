#!/usr/bin/env bash
set -Eeuo pipefail

readonly API_URL="${ARCH_LINUX_PACKAGE_API:-https://archlinux.org/packages/core/x86_64/linux/json/}"
readonly OUTPUT_FILE="${GITHUB_OUTPUT:-/dev/null}"
readonly SOURCE_REPO="${GREGKH_LINUX_REPO:-https://github.com/gregkh/linux.git}"
readonly SOURCE_PATH="drivers/net/wireless/intel/iwlwifi"

die() { echo "ERROR: $*" >&2; exit 1; }

# "6.12.4"  /  "6.12.4.arch1-1"  /  "6.12.4-arch1-1"  ->  "6.12.4"
kernel_base_version() {
    printf '%s\n' "$1" |
        sed -E 's/[.-]arch[0-9]+.*$//; s/-[0-9]+$//'
}

echo "==> Querying Arch Linux kernel package"
echo "    ${API_URL}"

package_json="$(curl --fail --silent --show-error --location \
    --retry 5 --retry-delay 3 --retry-all-errors \
    "${API_URL}")" || die "Failed to query Arch Linux API"

api_pkgver="$(jq -er '.pkgver | tostring' <<<"${package_json}")" ||
    die "Could not read .pkgver"

new_pkgver="$(kernel_base_version "${api_pkgver}")"
[[ -n "${new_pkgver}" ]] || die "Could not parse kernel version"

echo "    Arch pkgver: ${api_pkgver}"
echo "    Kernel base: ${new_pkgver}"

cd "${GITHUB_WORKSPACE:-$(pwd)}"

old_pkgver="$(sed -nE 's/^pkgver=([0-9][0-9.]*)$/\1/p' PKGBUILD | head -n 1)"
[[ -n "${old_pkgver}" ]] || die "Could not read pkgver from PKGBUILD"
echo "    Current PKGBUILD pkgver: ${old_pkgver}"

if [[ "${new_pkgver}" == "${old_pkgver}" ]]; then
    echo "==> Already up to date"
    { echo "changed=false"; echo "pkgver=${old_pkgver}"; } >>"${OUTPUT_FILE}"
    exit 0
fi

echo "==> Update required: ${old_pkgver} -> ${new_pkgver}"
readonly tag="v${new_pkgver}"

# ---- 1. Sparse clone of only iwlwifi ----
echo "==> Checking tag ${tag} availability"
if ! git ls-remote "${SOURCE_REPO}" "refs/tags/${tag}" 2>/dev/null | grep -q .; then
    echo "::warning::Tag ${tag} not yet present in ${SOURCE_REPO}"
    echo "::warning::Skipping this run; will retry next schedule"
    { echo "changed=false"; echo "pkgver=${old_pkgver}"; } >>"${OUTPUT_FILE}"
    exit 0
fi

readonly src_dir="/tmp/gregkh-linux-src"
echo "==> Sparse-cloning ${SOURCE_PATH} @ ${tag}"
rm -rf "${src_dir}"

git clone \
    --filter=blob:none \
    --sparse \
    --depth 1 \
    --branch "${tag}" \
    "${SOURCE_REPO}" \
    "${src_dir}"

git -C "${src_dir}" sparse-checkout set --no-cone "${SOURCE_PATH}"

iwlwifi_dir="${src_dir}/${SOURCE_PATH}"
[[ -d "${iwlwifi_dir}" ]] || die "iwlwifi directory missing at ${iwlwifi_dir}"

# ---- 2. Deterministic tarball: iwlwifi/ only, at top level ----
echo "==> Building iwlwifi-v${new_pkgver}.tar.gz"
cd "${GITHUB_WORKSPACE:-$(pwd)}"

# 删除其它版本的旧 tarball，避免历史里堆积多份内核源码
find . -maxdepth 1 -type f -name 'iwlwifi-v*.tar.gz' \
    -not -name "iwlwifi-v${new_pkgver}.tar.gz" \
    -print -delete

tar \
    --sort=name \
    --mtime='UTC 2020-01-01' \
    --owner=0 --group=0 --numeric-owner \
    --format=gnu \
    -cf - \
    -C "${src_dir}/drivers/net/wireless/intel" \
    iwlwifi \
    | gzip -n -9 >"iwlwifi-v${new_pkgver}.tar.gz"

[[ -s "iwlwifi-v${new_pkgver}.tar.gz" ]] || die "Failed to create tarball"
echo "    $(du -h "iwlwifi-v${new_pkgver}.tar.gz" | cut -f1)  iwlwifi-v${new_pkgver}.tar.gz"

# ---- 3. Update PKGBUILD ----
echo "==> Updating PKGBUILD"
sed -i -E "s/^pkgver=.*/pkgver=${new_pkgver}/" PKGBUILD
sed -i -E "s/^pkgrel=.*/pkgrel=1/" PKGBUILD
grep -E '^(pkgver|pkgrel)=' PKGBUILD

{
    echo "changed=true"
    echo "pkgver=${new_pkgver}"
    echo "release_tag=v${new_pkgver}-1"
} >>"${OUTPUT_FILE}"

echo "==> Done"
