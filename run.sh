#!/bin/bash

echo "Select environment to run:"
echo "1) Local"
echo "2) Production"
echo "3) Make & Migrate"
echo "4) Collect static files"
echo "9) Create new Django app"
read -p "Enter your choice (1, 2, 3, 4, or 9): " choice

case $choice in
    1)
        echo "Running with local settings..."
        uv run manage.py runserver --settings=config.settings.local
        ;;
    2)
        echo "Running with production settings..."
        uv run manage.py runserver --settings=config.settings.stage
        ;;
    3)
        echo "Making & migrating..."
        uv run manage.py makemigrations --settings=config.settings.stage
        uv run manage.py migrate
        uv run manage.py migrate --settings=config.settings.stage
        ;;
    4)
        echo "Collecting static files..."
        echo "yes" | uv run manage.py collectstatic --settings=config.settings.production
        echo "Static files collected successfully!"
        ;;
    9)
        read -p "Enter the app name: " app_name
        
        # Check if app name is empty
        if [ -z "$app_name" ]; then
            echo "Error: App name cannot be empty."
            exit 1
        fi
        
        # Check if app already exists
        if [ -d "apps/$app_name" ]; then
            echo "Error: App 'apps/$app_name' already exists."
            exit 1
        fi
        
        echo "Creating Django app '$app_name' in apps folder..."
        
        # Create directory and Django app
        mkdir -p apps/$app_name && uv run manage.py startapp $app_name apps/$app_name
        
        # Check if successful
        if [ $? -eq 0 ]; then
            echo "✓ Successfully created app: apps/$app_name"
            echo ""
            echo "Don't forget to add 'apps.$app_name' to INSTALLED_APPS in your settings!"
        else
            echo "✗ Failed to create app."
            exit 1
        fi
        ;;
    *)
        echo "Invalid choice. Defaulting to local settings..."
        uv run manage.py runserver --settings=config.settings.local
        ;;
esac