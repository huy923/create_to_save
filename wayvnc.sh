#!/bin/bash

# Detect IP address
if command -v ip >/dev/null 2>&1; then
    IP=$(ip route get 1.1.1.1 2>/dev/null | awk '{print $7; exit}')
elif command -v hostname >/dev/null 2>&1; then
    IP=$(hostname -I 2>/dev/null | awk '{print $1}')
    if [ -z "$IP" ]; then
        IP=$(hostname -i 2>/dev/null)
    fi
else
    echo "Cannot detect IP address automatically."
    IP="127.0.0.1"
fi

# Fallback if detection fails
if [ -z "$IP" ]; then
    IP="127.0.0.1"
fi

echo "🔍 Detected IP: $IP"

# Update docker-compose.yml with correct IP
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "🍎 Running on macOS"
    # Update APP_URL
    sed -i '' "s|APP_URL: http://[0-9.]*:8000|APP_URL: http://$IP:8000|" docker-compose.yml
    # Update FRONTEND_URL
    sed -i '' "s|FRONTEND_URL: http://[0-9.]*:3000|FRONTEND_URL: http://$IP:3000|" docker-compose.yml
    # Update SESSION_DOMAIN
    sed -i '' "s|SESSION_DOMAIN: [0-9.]*|SESSION_DOMAIN: $IP|" docker-compose.yml
    # Update SANCTUM_STATEFUL_DOMAINS
    sed -i '' "s|SANCTUM_STATEFUL_DOMAINS: [0-9.]*:3000|SANCTUM_STATEFUL_DOMAINS: $IP:3000|" docker-compose.yml
    # Update NEXT_PUBLIC_API_URL
    sed -i '' "s|NEXT_PUBLIC_API_URL: http://[0-9.]*:8000|NEXT_PUBLIC_API_URL: http://$IP:8000|" docker-compose.yml
else
    echo "🐧 Running on Linux/Windows"
    # Update APP_URL
    sed -i "s|APP_URL: http://[0-9.]*:8000|APP_URL: http://$IP:8000|" docker-compose.yml
    # Update FRONTEND_URL
    sed -i "s|FRONTEND_URL: http://[0-9.]*:3000|FRONTEND_URL: http://$IP:3000|" docker-compose.yml
    # Update SESSION_DOMAIN
    sed -i "s|SESSION_DOMAIN: [0-9.]*|SESSION_DOMAIN: $IP|" docker-compose.yml
    # Update SANCTUM_STATEFUL_DOMAINS
    sed -i "s|SANCTUM_STATEFUL_DOMAINS: [0-9.]*:3000|SANCTUM_STATEFUL_DOMAINS: $IP:3000|" docker-compose.yml
    # Update NEXT_PUBLIC_API_URL
    sed -i "s|NEXT_PUBLIC_API_URL: http://[0-9.]*:8000|NEXT_PUBLIC_API_URL: http://$IP:8000|" docker-compose.yml
fi

# Update backend .env if it exists
if [ -f "backend/.env" ]; then
    echo "📝 Updating backend/.env"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "s|APP_URL=.*|APP_URL=http://$IP:8000|" backend/.env
        sed -i '' "s|FRONTEND_URL=.*|FRONTEND_URL=http://$IP:3000|" backend/.env
    else
        sed -i "s|APP_URL=.*|APP_URL=http://$IP:8000|" backend/.env
        sed -i "s|FRONTEND_URL=.*|FRONTEND_URL=http://$IP:3000|" backend/.env
    fi
fi

# Update frontend .env.local if it exists
if [ -f "frontend/.env.local" ]; then
    echo "📝 Updating frontend/.env.local"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "s|NEXT_PUBLIC_API_URL=.*|NEXT_PUBLIC_API_URL=http://$IP:8000|" frontend/.env.local
    else
        sed -i "s|NEXT_PUBLIC_API_URL=.*|NEXT_PUBLIC_API_URL=http://$IP:8000|" frontend/.env.local
    fi
fi

# Update backend .env for Docker database connection
echo "📝 Updating backend/.env for Docker database..."
if [ ! -f "backend/.env" ]; then
    cp backend/.env.example backend/.env || true
fi

# Use platform-independent sed
if [[ "$OSTYPE" == "darwin"* ]]; then
    sed -i '' 's/DB_CONNECTION=.*/DB_CONNECTION=mysql/' backend/.env
    sed -i '' 's/DB_HOST=.*/DB_HOST=mysql/' backend/.env
    sed -i '' 's/DB_PORT=.*/DB_PORT=3306/' backend/.env
    sed -i '' 's/DB_DATABASE=.*/DB_DATABASE=GooglePhotosClone/' backend/.env
    sed -i '' 's/DB_USERNAME=.*/DB_USERNAME=user/' backend/.env
    sed -i '' 's/DB_PASSWORD=.*/DB_PASSWORD=password/' backend/.env
else
    sed -i 's/DB_CONNECTION=.*/DB_CONNECTION=mysql/' backend/.env
    sed -i 's/DB_HOST=.*/DB_HOST=mysql/' backend/.env
    sed -i 's/DB_PORT=.*/DB_PORT=3306/' backend/.env
    sed -i 's/DB_DATABASE=.*/DB_DATABASE=GooglePhotosClone/' backend/.env
    sed -i 's/DB_USERNAME=.*/DB_USERNAME=user/' backend/.env
    sed -i 's/DB_PASSWORD=.*/DB_PASSWORD=password/' backend/.env
fi

echo ""
echo "✅ Configuration updated!"
echo "🚀 API URL: http://$IP:8000"
echo "🌐 Frontend URL: http://$IP:3000"
echo "📊 MySQL: localhost:3307"
echo ""

# Fix storage permissions before starting
echo "🔧 Creating storage directories..."
mkdir -p backend/storage/framework/sessions
mkdir -p backend/storage/framework/views
mkdir -p backend/storage/framework/cache/data
mkdir -p backend/storage/logs
mkdir -p backend/storage/app/public
mkdir -p backend/bootstrap/cache

echo "🔒 Setting permissions..."
chmod -R 777 backend/storage
chmod -R 775 backend/bootstrap/cache

# Stop existing containers
echo "🛑 Stopping existing containers..."
docker-compose down -v

# Rebuild and start
echo "🔨 Building and starting containers..."
docker-compose up --build -d 
docker exec backend php artisan migrate --path=database/database.php --force 2>&1 | head -100
# Wait for services to be ready
echo "⏳ Waiting for services to start..."
sleep 10

# Fix permissions inside container
echo "🔧 Fixing permissions inside container..."
docker exec backend chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache || true
docker exec backend chmod -R 775 /var/www/html/storage /var/www/html/bootstrap/cache || true

# Clear caches
echo "🧹 Clearing caches..."
docker exec backend php artisan config:clear || true
docker exec backend php artisan cache:clear || true

# Show logs
echo ""
echo "📋 Container Status:"
docker-compose ps

echo ""
echo "✅ Setup complete! Access your app at:"
echo "   Frontend: http://$IP:3000"
echo "   Backend:  http://$IP:8000"
echo ""
echo "To view logs: docker-compose logs -f"
