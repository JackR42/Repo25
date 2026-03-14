# Repo25
POC SQL Server 2025

## Dev Container

This repository includes a dev container that runs **SQL Server 2025 Enterprise Developer Edition** alongside an Ubuntu-based development environment.

### Prerequisites

- [Docker](https://www.docker.com/)
- [VS Code](https://code.visualstudio.com/) with the [Dev Containers extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)

### Getting started

1. Copy the example environment file and set a strong SA password:

   ```bash
   cp .devcontainer/.env.example .devcontainer/.env
   # Edit .devcontainer/.env and update MSSQL_SA_PASSWORD
   ```

2. Open the repository in VS Code and click **Reopen in Container** when prompted (or run **Dev Containers: Reopen in Container** from the Command Palette).

3. SQL Server 2025 will start automatically. Connect to it using the **SQL Server** VS Code extension (`ms-mssql.mssql`) with:
   - **Server:** `sqlserver`
   - **Authentication:** SQL Login
   - **Username:** `sa`
   - **Password:** *(the value from your `.env` file)*

### Automatic database reset on restart

Each time the dev container starts, it runs `.devcontainer/init.sh`, which executes `.devcontainer/init.sql` to drop and recreate the `POC25` database. This guarantees a clean `POC25` database on every restart.

> **Note:** Port `1433` is forwarded to your local machine so you can also connect with any SQL client (e.g. Azure Data Studio, SSMS) at `localhost,1433`.
