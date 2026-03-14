#!/usr/bin/env bash

# Load centralized deployment variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/deploy.env" ]; then
    source "$SCRIPT_DIR/deploy.env"
else
    echo "Error: deploy.env not found in $SCRIPT_DIR"
    exit 1
fi

# Add menu to choose between new, old, and restart-only instance
echo "---------------------------------------"
echo "Welcome to the $PROJECT_NAME Setup"
echo "---------------------------------------"
echo "Please select an option:"
echo "1. New Instance (Full installation)"
echo "2. Old Instance (Skip system dependencies)"
echo "3. Restart Only (Nginx & Gunicorn only)"
echo "---------------------------------------"
read -p "Enter your choice (1, 2 or 3): " choice

# Check if the input is valid
while [[ "$choice" != "1" && "$choice" != "2" && "$choice" != "3" ]]; do
    echo "Invalid input. Please enter 1, 2 or 3."
    read -p "Enter your choice (1, 2 or 3): " choice
done

# Add environment selection menu
echo "---------------------------------------"
echo "Please select the environment:"
echo "1. Stage"
echo "2. Live"
echo "---------------------------------------"
read -p "Enter your choice (1 or 2): " env_choice

# Check if the environment input is valid
while [[ "$env_choice" != "1" && "$env_choice" != "2" ]]; do
    echo "Invalid input. Please enter 1 or 2."
    read -p "Enter your choice (1 or 2): " env_choice
done

# Set environment strings based on choice
if [[ "$env_choice" == "1" ]]; then
    ENV_FOLDER="stage"
    TARGET_DIR="$STAGE_FOLDER"
    DOMAIN="$STAGE_DOMAIN"
    echo "Selected environment: Stage (Target: $DEPLOY_PATH/$TARGET_DIR)"
else
    ENV_FOLDER="live"
    TARGET_DIR="$LIVE_FOLDER"
    DOMAIN="$LIVE_DOMAIN"
    echo "Selected environment: Live (Target: $DEPLOY_PATH/$TARGET_DIR)"
fi

# Option 3: Restart only
if [[ "$choice" == "3" ]]; then
    echo "Selected: Restart Only - Restarting Nginx and Gunicorn services..."
    sudo systemctl restart $PROJECT_NAME.service
    sudo systemctl reload nginx
    echo "Restart completed!"
    exit 0
fi

# Option 1: New instance (install everything)
if [[ "$choice" == "1" ]]; then
    echo "Selected: New Instance - Installing all dependencies..."

    sudo apt-get update
    sudo apt-get upgrade -y

    # Install Nginx
    sudo apt install -y nginx

    # Install PostgreSQL development packages (required for psycopg2)
    sudo apt-get install -y postgresql-server-dev-all libpq-dev

    # Install Python3 pip
    sudo apt install -y python3-pip

    # Install uv for Python package management
    echo "Installing uv..."
    curl -LsSf https://astral.sh/uv/install.sh | sh
    # Ensure uv is in the path for the current script
    export PATH="$HOME/.local/bin:$PATH"

    # Install Virtualenv
    sudo apt-get install python3-venv -y
else
    echo "Selected: Old Instance - Skipping system dependencies installation..."
    # Ensure uv is in the path even for old instances
    export PATH="$HOME/.local/bin:$PATH"
fi

# Common steps for both new and old instances
echo "Performing common setup steps..."

# Change ownership and permissions
sudo chown -R $USER:$USER "$DEPLOY_PATH/$TARGET_DIR"
sudo chmod -R 755 "$DEPLOY_PATH/$TARGET_DIR"

# Template Processing Function
process_template() {
    local src=$1
    local dest=$2
    sed -e "s|{{PROJECT_NAME}}|$PROJECT_NAME|g" \
        -e "s|{{DEPLOY_USER}}|$DEPLOY_USER|g" \
        -e "s|{{DEPLOY_PATH}}|$DEPLOY_PATH|g" \
        -e "s|{{STAGE_DOMAIN}}|$STAGE_DOMAIN|g" \
        -e "s|{{STAGE_FOLDER}}|$STAGE_FOLDER|g" \
        -e "s|{{LIVE_DOMAIN}}|$LIVE_DOMAIN|g" \
        -e "s|{{LIVE_FOLDER}}|$LIVE_FOLDER|g" \
        "$src" > "$dest"
}

echo "Generating and copying gunicorn.service file..."
process_template "$DEPLOY_PATH/$TARGET_DIR/server/$ENV_FOLDER/gunicorn.service" "/tmp/gunicorn.service"
sudo cp "/tmp/gunicorn.service" "/etc/systemd/system/$PROJECT_NAME.service"

sudo systemctl daemon-reload
sudo systemctl start $PROJECT_NAME
sudo systemctl enable $PROJECT_NAME

echo "Generating and copying nginx.conf file..."
process_template "$DEPLOY_PATH/$TARGET_DIR/server/$ENV_FOLDER/nginx.conf" "/tmp/nginx.conf"
sudo cp "/tmp/nginx.conf" "/etc/nginx/sites-available/$PROJECT_NAME.conf"
sudo ln -sf "/etc/nginx/sites-available/$PROJECT_NAME.conf" "/etc/nginx/sites-enabled/"

sudo nginx -t
sudo systemctl restart nginx
sudo systemctl reload nginx

# Create virtual environment using uv
echo "Creating virtual environment with uv..."
cd "$DEPLOY_PATH/$TARGET_DIR"
uv venv "$DEPLOY_PATH/$TARGET_DIR/venv"

# Change ownership and permissions
sudo chown -R $USER:$USER "$DEPLOY_PATH/$TARGET_DIR/venv"
sudo chmod -R 755 "$DEPLOY_PATH/$TARGET_DIR/venv"
sudo chmod -R 755 "$DEPLOY_PATH/$TARGET_DIR/server"

# Install requirements using uv
echo "Installing requirements with uv..."
source "$DEPLOY_PATH/$TARGET_DIR/venv/bin/activate"

# Sync dependencies from pyproject.toml / uv.lock
uv sync --frozen

# Migrate
echo "Migrating..."
uv run python manage.py migrate --settings=config.settings.production

# Collect static
echo "Collecting static files..."
uv run python manage.py collectstatic --noinput --settings=config.settings.production

# Restart services
echo "Restarting Gunicorn and Nginx..."
sudo systemctl daemon-reload
sudo systemctl restart $PROJECT_NAME.service
sudo systemctl reload nginx
sudo systemctl restart nginx

echo "Setup completed successfully for $PROJECT_NAME ($ENV_FOLDER environment)!"
