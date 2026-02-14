#!/bin/bash
# Finn - Run Production

# Exit on error
set -e

# Load environment
if [ ! -f .env.prod ]; then
    echo "❌ .env.prod not found!"
    echo "Copy .env.example to .env.prod and configure it"
    exit 1
fi

# Copy to .env (flutter_dotenv reads from .env)
cp .env.prod .env

echo "💰 Starting Finn (Production)"
echo "📡 Supabase: $(grep SUPABASE_URL .env.prod | cut -d'=' -f2)"
echo "🔒 HTTPS Secure Connection"
echo ""

flutter run --release
