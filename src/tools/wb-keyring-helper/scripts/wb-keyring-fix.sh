#!/bin/bash
#
# wb-keyring-fix.sh
# 依据 wb-keyring-check 的检测结果，对指定用户的白盒 login.keyring 进行扫描与可选修复。

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_PREFIX="/usr/lib/deepin-doctor/tools"
LEGACY_PREFIX="/usr/lib/deepin/wb-keyring-helper"
DEFAULT_CHECK_BIN="${SCRIPT_DIR}/wb-keyring-check"
PARENT_CHECK_BIN="${SCRIPT_DIR}/../wb-keyring-check"
INSTALLED_CHECK_BIN="${INSTALL_PREFIX}/wb-keyring-check"
LEGACY_CHECK_BIN="${LEGACY_PREFIX}/wb-keyring-check"
# Allow overriding the checker location while preferring the installed tree.
if [[ -n "${WB_KEYRING_CHECK_BIN:-}" ]]; then
    CHECK_BIN="${WB_KEYRING_CHECK_BIN}"
elif [[ -x "${SCRIPT_DIR}/wb-keyring-check" ]]; then
    CHECK_BIN="${SCRIPT_DIR}/wb-keyring-check"
elif [[ -x "${PARENT_CHECK_BIN}" ]]; then
    CHECK_BIN="${PARENT_CHECK_BIN}"
elif [[ -x "${INSTALLED_CHECK_BIN}" ]]; then
    CHECK_BIN="${INSTALLED_CHECK_BIN}"
elif [[ -x "${LEGACY_CHECK_BIN}" ]]; then
    CHECK_BIN="${LEGACY_CHECK_BIN}"
else
    CHECK_BIN="${DEFAULT_CHECK_BIN}"
fi

KEYRING_FILE="login.keyring"
LOG_TAG="wb-keyring-fix"
RUN_CHECK_DETAIL=""

log_msg() {
    echo "[${LOG_TAG}] $1"
    logger -t "${LOG_TAG}" "$1" 2>/dev/null || true
}

sanitize_detail() {
    local detail="$1"
    detail="${detail//$'\n'/; }"
    detail="${detail//$'\r'/}"
    printf "%s" "${detail}"
}

run_check() {
    local user="$1"
    local dir="$2"
    local file="${dir}/${KEYRING_FILE}"
    RUN_CHECK_DETAIL=""

    if [[ -L "${file}" ]]; then
        printf "%s" "error"
        RUN_CHECK_DETAIL="keyring symlink: ${file}"
        return 0
    fi
    if [[ -e "${file}" && ! -f "${file}" ]]; then
        printf "%s" "error"
        RUN_CHECK_DETAIL="keyring not regular file: ${file}"
        return 0
    fi
    if [[ ! -f "${file}" ]]; then
        printf "%s" "missing"
        RUN_CHECK_DETAIL="keyring missing: ${file}"
        return 0
    fi
    local output rc
    if output=$("${CHECK_BIN}" --user="${user}" --keyring-path="${file}" 2>&1); then
        RUN_CHECK_DETAIL="${output}"
        printf "%s" "ok"
        return 0
    fi
    rc=$?
    if [[ ${rc} -eq 1 ]]; then
        RUN_CHECK_DETAIL="${output}"
        printf "%s" "bad"
    else
        RUN_CHECK_DETAIL="${output:-checker exited ${rc}}"
        printf "%s" "error"
    fi
    return 0
}

copy_keyring() {
    local src="$1"
    local dst_dir="$2"
    local dst="${dst_dir}/${KEYRING_FILE}"

    if [[ -L "${src}" ]]; then
        return 1
    fi
    if [[ ! -f "${src}" ]]; then
        return 1
    fi
    umask 077
    install -m 600 "${src}" "${dst}.tmp"
    chown "$(stat -c %u "${dst_dir}")":"$(stat -c %g "${dst_dir}")" "${dst}.tmp"
    mv -f "${dst}.tmp" "${dst}"
    return 0
}

copy_default_keyring_to_wb() {
    local user="$1"
    local default_dir="$2"
    local wb_dir="$3"

    log_msg "${user}: copying default keyring to whitebox."
    if copy_keyring "${default_dir}/${KEYRING_FILE}" "${wb_dir}"; then
        local verify
        verify=$(run_check "${user}" "${wb_dir}")
        log_msg "${user}: after copy whitebox=${verify}"
    else
        log_msg "${user}: copy failed."
    fi
}

canonicalize_existing_path() {
    local path="$1"
    realpath -e "${path}"
}

path_has_symlink_component() {
    local target="$1"
    local prefix=""
    local trimmed="${target#/}"
    local part
    local IFS='/'
    local -a parts=()

    if [[ "${target}" == /* ]]; then
        prefix="/"
    fi

    if [[ -n "${trimmed}" ]]; then
        read -ra parts <<< "${trimmed}"
    fi
    for part in "${parts[@]}"; do
        [[ -z "${part}" ]] && continue
        if [[ "${prefix}" == "/" ]]; then
            prefix="/${part}"
        elif [[ -z "${prefix}" ]]; then
            prefix="${part}"
        else
            prefix="${prefix}/${part}"
        fi
        if [[ -L "${prefix}" ]]; then
            return 0
        fi
    done

    return 1
}

validate_dir_within_home() {
    local user="$1"
    local dir="$2"
    local home_real="$3"
    local label="$4"
    local resolved
    local base home_with_slash

    if path_has_symlink_component "${dir}"; then
        log_msg "${user}: skip ${label} directory ${dir}: symlink detected"
        return 1
    fi

    if ! resolved=$(canonicalize_existing_path "${dir}" 2>/dev/null); then
        log_msg "${user}: skip ${label} directory ${dir}: cannot resolve"
        return 1
    fi

    base="${home_real%/}"
    if [[ -z "${base}" ]]; then
        base="${home_real}"
    fi
    home_with_slash="${base}/"
    if [[ "${base}" == "/" ]]; then
        home_with_slash="/"
    fi

    if [[ "${resolved}" != "${base}" && "${resolved:0:${#home_with_slash}}" != "${home_with_slash}" ]]; then
        log_msg "${user}: skip ${label} directory ${dir}: outside home"
        return 1
    fi

    printf "%s" "${resolved}"
    return 0
}

remove_keyring() {
    local dir="$1"
    local target="${dir}/${KEYRING_FILE}"
    if [[ -f "${target}" ]]; then
        rm -f "${target}"
    fi
}

fix_for_user() {
    local user="$1"
    local do_fix="$2"
    local home_dir
    home_dir=$(getent passwd "${user}" | cut -d: -f6)
    if [[ -z "${home_dir}" || ! -d "${home_dir}" ]]; then
        log_msg "skip ${user}: home directory missing"
        return
    fi

    local home_realpath
    if ! home_realpath=$(canonicalize_existing_path "${home_dir}" 2>/dev/null); then
        log_msg "skip ${user}: cannot resolve home directory"
        return
    fi

    local wb_dir="${home_dir}/.local/share/deepin-keyrings-wb"
    local default_dir="${home_dir}/.local/share/keyrings"

    if [[ ! -d "${wb_dir}" ]]; then
        log_msg "skip ${user}: ${wb_dir} missing"
        return
    fi

    if ! wb_dir=$(validate_dir_within_home "${user}" "${wb_dir}" "${home_realpath}" "whitebox"); then
        return
    fi

    if [[ -d "${default_dir}" ]]; then
        local resolved_default
        if ! resolved_default=$(validate_dir_within_home "${user}" "${default_dir}" "${home_realpath}" "default"); then
            return
        fi
        default_dir="${resolved_default}"
    fi

    local wb_status default_status
    local wb_detail default_detail
    wb_status=$(run_check "${user}" "${wb_dir}")
    wb_detail="${RUN_CHECK_DETAIL}"
    default_status=$(run_check "${user}" "${default_dir}")
    default_detail="${RUN_CHECK_DETAIL}"

    log_msg "${user}: whitebox=${wb_status}, default=${default_status}"
    if [[ "${wb_status}" != "ok" && -n "${wb_detail}" ]]; then
        log_msg "${user}: whitebox detail: $(sanitize_detail "${wb_detail}")"
    fi
    if [[ "${default_status}" != "ok" && -n "${default_detail}" ]]; then
        log_msg "${user}: default detail: $(sanitize_detail "${default_detail}")"
    fi

    if [[ "${wb_status}" == "missing" ]]; then
        if [[ "${default_status}" == "ok" ]]; then
            log_msg "${user}: whitebox keyring missing, default ok."
            if [[ "${do_fix}" == "true" ]]; then
                copy_default_keyring_to_wb "${user}" "${default_dir}" "${wb_dir}"
            fi
        else
            log_msg "${user}: whitebox keyring missing, nothing to do."
        fi
        return
    fi

    if [[ "${wb_status}" == "ok" ]]; then
        log_msg "${user}: whitebox keyring is already unlockable, nothing to do."
        return
    fi

    if [[ "${default_status}" == "ok" ]]; then
        log_msg "${user}: whitebox bad, default ok."
        if [[ "${do_fix}" == "true" ]]; then
            copy_default_keyring_to_wb "${user}" "${default_dir}" "${wb_dir}"
        fi
        return
    fi

    if [[ "${default_status}" == "bad" || "${default_status}" == "missing" ]]; then
        log_msg "${user}: both whitebox and default keyrings invalid."
        if [[ "${do_fix}" == "true" ]]; then
            log_msg "${user}: removing invalid whitebox keyring."
            remove_keyring "${wb_dir}"
        fi
        return
    fi

    if [[ "${wb_status}" == "error" || "${default_status}" == "error" ]]; then
        log_msg "${user}: checker error, skip."
        return
    fi
}

collect_users() {
    local mode="$1"
    local arg="$2"
    case "${mode}" in
        single)
            printf "%s\n" "${arg}"
            ;;
        all)
            getent passwd | awk -F: '$3>=1000 && $1!="nobody" {print $1}'
            ;;
    esac
}

main() {
    local target_mode="single"
    local target_user="${USER:-}"
    local do_fix="false"

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --user=*)
                target_mode="single"
                target_user="${1#*=}"
                ;;
            --all-users)
                target_mode="all"
                ;;
            --fix)
                do_fix="true"
                ;;
            --help)
                cat <<EOF
Usage: $0 [--user=<name>] [--all-users] [--fix]
  --user=<name>   检查指定用户
  --all-users     检查所有普通用户 (UID>=1000)
  --fix           检测到问题后执行复制/删除
EOF
                return 0
                ;;
            *)
                echo "Unknown argument: $1"
                return 1
                ;;
        esac
        shift
    done

    if [[ ! -x "${CHECK_BIN}" ]]; then
        log_msg "checker binary missing at ${CHECK_BIN}"
        return 1
    fi

    if [[ "${target_mode}" == "single" ]]; then
        if [[ -z "${target_user}" ]]; then
            log_msg "USER env empty, specify --user."
            return 1
        fi
        if [[ "${target_user}" == "root" && "${EUID}" -eq 0 ]]; then
            log_msg "Running as root without explicit target; use --user=<name> or --all-users."
            return 1
        fi
    fi

    while IFS= read -r user; do
        [[ -z "${user}" ]] && continue
        fix_for_user "${user}" "${do_fix}"
    done < <(collect_users "${target_mode}" "${target_user}")
}

main "$@"
