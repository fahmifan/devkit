{
  description = "A flake to install and configure PostgreSQL as a non-root user service.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { 
        inherit system;
        config.allowUnfree = true;
      };
      
      # PostgreSQL configuration
      postgresql = pkgs.postgresql_16;
      pgPort = "5432";
      pgHome="$HOME/pgsql";
      pgDataDir = "$HOME/pgsql/data";
      systemdUserDir = "$HOME/.config/systemd/user";

      pgSystemdService = pkgs.writeTextFile {
        name = "postgresql.service";
        destination = "/lib/systemd/user/postgresql.service";
        text = ''
          [Unit]
          Description=PostgreSQL Database

          [Service]
          Type=simple
          # Debug: print environment and directory information
          ExecStartPre=${pkgs.coreutils}/bin/pwd
          ExecStartPre=${pkgs.coreutils}/bin/ls -la %h/pgsql/
          ExecStartPre=${pkgs.coreutils}/bin/ls -la %h/pgsql/data/
          ExecStartPre=${pkgs.bash}/bin/bash -c 'echo "PATH=$PATH"'
          # Use absolute paths for everything
          ExecStart=${postgresql}/bin/postgres \
            -D %h/pgsql/data \
            -k %h/pgsql/run \
            -c config_file=%h/pgsql/data/postgresql.conf \
            -c hba_file=%h/pgsql/data/pg_hba.conf
          Environment=PATH=${postgresql}/bin:${pkgs.coreutils}/bin:$PATH
          Environment=PGDATA=%h/pgsql/data
          StandardOutput=journal
          StandardError=journal
          LogLevelMax=debug
          WorkingDirectory=%h/pgsql
          Restart=always

          [Install]
          WantedBy=default.target
        '';
      };
    in
    
    flake-utils.lib.eachSystem [ system ] (system: {
      packages = rec {
        default = pgSetup;
        inherit postgresql;
        pgSetup = pkgs.writeScriptBin "pg-setup" ''
          #!${pkgs.bash}/bin/bash

          # Check if running as root during nix-build
          if [ "$USER" = "root" ]; then
            echo "Setup script is being built. Skipping systemd service installation."
            exit 0
          fi

          # Read from .env file if it exists
          if [ -f .env ]; then
            set -o allexport
            source .env
            set +o allexport
          fi

          # Use env vars with defaults
          PG_USER=''${POSTGRES_USER:-nixpostgres}
          PG_PASSWORD=''${POSTGRES_PASSWORD:-nixpostgres}

          # Ensure the script has access to required runtime dependencies
          export PATH="${postgresql}/bin:${pkgs.coreutils}/bin:$PATH"

          # Set locale
          export LOCALE_ARCHIVE=${pkgs.glibcLocales}/lib/locale/locale-archive
          export LANG=C.UTF-8  # Using C.UTF-8 which is usually available
          export LC_ALL=C.UTF-8

          # Create data directory if it doesn't exist
          if [ ! -d "${pgDataDir}" ]; then
            mkdir -p "${pgDataDir}"
            chmod 0700 "${pgDataDir}"
          fi

          # Create systemd user directory if it doesn't exist
          if [ ! -d "${systemdUserDir}" ]; then
            mkdir -p "${systemdUserDir}"
            chmod 700 "${systemdUserDir}"
          fi

          # Initialize database if not already initialized
          if [ ! -f "${pgDataDir}/PG_VERSION" ]; then
          ${postgresql}/bin/initdb -D "${pgDataDir}" \
            --auth=trust \
            --username=$PG_USER \
            --locale=C.UTF-8
              
          # Configure postgresql.conf
          cat > "${pgDataDir}/postgresql.conf" << EOF
          listen_addresses = '*'
          port = ${pgPort}
          max_connections = 100
          shared_buffers = 128MB
          dynamic_shared_memory_type = posix
          EOF
          
          # Configure pg_hba.conf for password authentication
          cat > "${pgDataDir}/pg_hba.conf" << EOF
          # TYPE  DATABASE        USER            ADDRESS                 METHOD
          local   all             all                                     trust
          host    all             all             127.0.0.1/32           scram-sha-256
          host    all             all             ::1/128                scram-sha-256
          host    all             all             0.0.0.0/0              scram-sha-256
          EOF

          # Update postgresql.conf to use more secure password encryption
          cat > "${pgDataDir}/postgresql.conf" << EOF
          listen_addresses = '*'
          port = ${pgPort}
          max_connections = 100
          shared_buffers = 128MB
          dynamic_shared_memory_type = posix
          password_encryption = scram-sha-256
          EOF
          fi

          # Start PostgreSQL temporarily to set up the user
          ${postgresql}/bin/pg_ctl -D "${pgDataDir}" \
            -l $HOME/pgsql/data/logfile \
            start -w \
            -o "-k $HOME/pgsql/run \
                -c config_file=$HOME/pgsql/data/postgresql.conf \
                -c hba_file=$HOME/pgsql/data/pg_hba.conf"
          
          # Debug: check if postgres is running
          echo "Checking PostgreSQL process..."
          ps aux | grep postgres

          echo "Waiting for PostgreSQL to be ready..."
          for i in {1..30}; do
            if ${postgresql}/bin/pg_isready -h $HOME/pgsql/run -p 5432; then
              echo "PostgreSQL is ready!"
              break
            fi
            echo "Attempt $i: Waiting for PostgreSQL..."
            echo "Checking socket file..."
            ls -la $HOME/pgsql/run/
            sleep 1
          done

          # Create user if it doesn't exist and set password
          ${postgresql}/bin/psql -U postgres -h $HOME/pgsql/run -d postgres <<EOF
          DO \$\$
          BEGIN
            IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = '$PG_USER') THEN
              CREATE USER $PG_USER;
            END IF;
            ALTER USER $PG_USER WITH PASSWORD '$PG_PASSWORD' SUPERUSER;
          END
          \$\$;
          EOF

          ${postgresql}/bin/pg_ctl -D "${pgDataDir}" stop

          # Copy systemd service 
          rm -f "${systemdUserDir}/postgresql.service"
          cp -f ${pgSystemdService}/lib/systemd/user/postgresql.service "${systemdUserDir}/"
          
          echo "PostgreSQL has been configured."
          echo "To start PostgreSQL manually: pg_ctl -D ${pgDataDir} start"
          echo ""
          echo "Or to use systemd:"
          echo "systemctl --user enable postgresql"
          echo "systemctl --user start postgresql"
        '';
      };
    });
} 