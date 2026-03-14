#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="${SCRIPT_DIR}/.env"
INIT_SQL_FILE="${SCRIPT_DIR}/init.sql"
SQL_HOST="SQL1"
SQL_USER="sa"
DB_NAME="POC25"

if [[ ! -f "${ENV_FILE}" ]]; then
  echo "Missing ${ENV_FILE}. Copy .env.example to .env first."
  exit 1
fi

if [[ ! -f "${INIT_SQL_FILE}" ]]; then
  echo "Missing ${INIT_SQL_FILE}."
  exit 1
fi

set -a
# shellcheck disable=SC1090
source "${ENV_FILE}"
set +a

if [[ -z "${MSSQL_SA_PASSWORD:-}" ]]; then
  echo "MSSQL_SA_PASSWORD is not set in ${ENV_FILE}."
  exit 1
fi

install_sqlcmd_if_missing() {
  if command -v sqlcmd >/dev/null 2>&1; then
    return
  fi

  if [[ -x /opt/mssql-tools18/bin/sqlcmd ]]; then
    export PATH="$PATH:/opt/mssql-tools18/bin"
    return
  fi

  echo "Installing sqlcmd tools..."
  sudo mkdir -p /etc/apt/keyrings

  if [[ ! -f /etc/apt/keyrings/microsoft.gpg ]]; then
    curl -fsSL -o /tmp/microsoft.asc https://packages.microsoft.com/keys/microsoft.asc
    gpg --dearmor --batch --yes -o /tmp/microsoft.gpg /tmp/microsoft.asc
    sudo install -D -m 0644 /tmp/microsoft.gpg /etc/apt/keyrings/microsoft.gpg
  fi

  if [[ ! -f /etc/apt/sources.list.d/microsoft-prod.list ]]; then
    printf '%s\n' "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/microsoft.gpg] https://packages.microsoft.com/ubuntu/24.04/prod noble main" \
      | sudo tee /etc/apt/sources.list.d/microsoft-prod.list >/dev/null
  fi

  sudo apt-get update -qq
  DEBIAN_FRONTEND=noninteractive sudo ACCEPT_EULA=Y apt-get install -y -qq mssql-tools18 unixodbc-dev >/dev/null
  export PATH="$PATH:/opt/mssql-tools18/bin"
}

wait_for_sqlserver() {
  local attempts=60
  local i

  for ((i=1; i<=attempts; i++)); do
    if sqlcmd -C -S "${SQL_HOST}" -U "${SQL_USER}" -P "${MSSQL_SA_PASSWORD}" -Q "SELECT 1" >/dev/null 2>&1; then
      return 0
    fi
    sleep 2
  done

  echo "SQL Server did not become ready in time."
  return 1
}

install_sqlcmd_if_missing
wait_for_sqlserver

sqlcmd -C -S "${SQL_HOST}" -U "${SQL_USER}" -P "${MSSQL_SA_PASSWORD}" -i "${INIT_SQL_FILE}"

echo "Database ${DB_NAME} recreated successfully."