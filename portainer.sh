#!/bin/bash

# Portainer Standalone Installation Script
# Install Portainer with Docker and Nginx SSL
# Create by DefendX1 Team
# https://defendx1.com/
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

print_color() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

print_banner() {
    clear
    print_color $CYAN "======================================"
    print_color $CYAN "     🐳 Portainer Installation 🐳"
    print_color $CYAN "======================================"
    print_color $YELLOW "    Container Management Platform"
    print_color $CYAN "======================================"
    echo
}

check_prerequisites() {
    print_color $BLUE "🔍 Checking prerequisites..."
    
    if [ "$EUID" -ne 0 ]; then
        print_color $RED "❌ Please run as root or with sudo"
        exit 1
    fi
    
    # Install Docker if not present
    if ! command -v docker &> /dev/null; then
        print_color $YELLOW "📦 Installing Docker..."
        curl -fsSL https://get.docker.com -o get-docker.sh
        sh get-docker.sh
        systemctl start docker
        systemctl enable docker
        rm get-docker.sh
    fi
    
    # Install Docker Compose if not present
    if ! command -v docker-compose &> /dev/null; then
        print_color $YELLOW "📦 Installing Docker Compose..."
        curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        chmod +x /usr/local/bin/docker-compose
    fi
    
    # Install Nginx if not present
    if ! command -v nginx &> /dev/null; then
        print_color $YELLOW "📦 Installing Nginx..."
        apt update
        apt install -y nginx
        systemctl start nginx
        systemctl enable nginx
    fi
    
    # Install Certbot if not present
    if ! command -v certbot &> /dev/null; then
        print_color $YELLOW "📦 Installing Certbot..."
        apt update
        apt install -y certbot python3-certbot-nginx
    fi
    
    print_color $GREEN "✅ Prerequisites ready!"
}

get_configuration() {
    print_banner
    print_color $YELLOW "🌐 Configuration Setup"
    echo
    
    # Get domain
    read -p "Enter domain for Portainer (e.g., portainer.yourdomain.com): " PORTAINER_DOMAIN
    if [ -z "$PORTAINER_DOMAIN" ]; then
        print_color $RED "❌ Domain cannot be empty"
        get_configuration
    fi
    
    # Get email for SSL
    read -p "Enter email for SSL certificate: " SSL_EMAIL
    if [ -z "$SSL_EMAIL" ]; then
        print_color $RED "❌ Email cannot be empty"
        get_configuration
    fi
    
    # Check port conflicts
    PORTAINER_PORT=9000
    PORTAINER_EDGE_PORT=8000
    
    while netstat -tlnp | grep ":$PORTAINER_PORT " > /dev/null 2>&1; do
        PORTAINER_PORT=$((PORTAINER_PORT + 1))
    done
    
    while netstat -tlnp | grep ":$PORTAINER_EDGE_PORT " > /dev/null 2>&1; do
        PORTAINER_EDGE_PORT=$((PORTAINER_EDGE_PORT + 1))
    done
    
    print_color $GREEN "✅ Configuration complete!"
    print_color $BLUE "   Domain: $PORTAINER_DOMAIN"
    print_color $BLUE "   Main Port: $PORTAINER_PORT"
    print_color $BLUE "   Edge Port: $PORTAINER_EDGE_PORT"
    sleep 2
}

install_portainer() {
    print_color $BLUE "📁 Creating directory structure..."
    mkdir -p /opt/portainer/{portainer-data,portainer-ssl}
    
    cd /opt/portainer
    
    print_color $BLUE "🐳 Creating Docker Compose configuration..."
    cat > docker-compose.yml << EOF
version: '3.8'

services:
  portainer:
    image: portainer/portainer-ce:latest
    container_name: portainer
    restart: unless-stopped
    ports:
      - "127.0.0.1:${PORTAINER_PORT}:9000"
      - "127.0.0.1:${PORTAINER_EDGE_PORT}:8000"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - ./portainer-data:/data
    networks:
      - portainer-network
    command: --admin-password-file=/data/admin_password

networks:
  portainer-network:
    driver: bridge
EOF

    # Generate a random admin password
    ADMIN_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-16)
    
    # Hash the password for Portainer
    HASHED_PASSWORD=$(htpasswd -bnBC 10 "" "$ADMIN_PASSWORD" | tr -d ':\n' | sed 's/\$2y/\$2a/')
    
    # Save the hashed password to a file
    echo "$HASHED_PASSWORD" > portainer-data/admin_password
    
    cat > .env << EOF
PORTAINER_DOMAIN=${PORTAINER_DOMAIN}
PORTAINER_PORT=${PORTAINER_PORT}
PORTAINER_EDGE_PORT=${PORTAINER_EDGE_PORT}
ADMIN_PASSWORD=${ADMIN_PASSWORD}
SSL_EMAIL=${SSL_EMAIL}
EOF

    print_color $BLUE "🚀 Starting Portainer..."
    docker-compose up -d
    
    sleep 15
    
    if docker-compose ps | grep -q "portainer.*Up"; then
        print_color $GREEN "✅ Portainer container is running"
        
        local_test=$(curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:${PORTAINER_PORT}/ 2>/dev/null || echo "000")
        if [ "$local_test" = "200" ] || [ "$local_test" = "302" ]; then
            print_color $GREEN "✅ Portainer is responding locally ($local_test)"
        else
            print_color $YELLOW "⚠️  Portainer local response: $local_test"
        fi
    else
        print_color $RED "❌ Portainer failed to start"
        docker-compose logs
        exit 1
    fi
}

configure_nginx() {
    print_color $BLUE "🌐 Configuring Nginx..."
    
    # Initial HTTP configuration
    cat > /etc/nginx/sites-available/${PORTAINER_DOMAIN} << EOF
server {
    listen 80;
    server_name ${PORTAINER_DOMAIN};
    
    location /.well-known/acme-challenge/ {
        root /var/www/html;
    }
    
    location / {
        return 301 https://\$server_name\$request_uri;
    }
}
EOF

    ln -sf /etc/nginx/sites-available/${PORTAINER_DOMAIN} /etc/nginx/sites-enabled/
    nginx -t && systemctl reload nginx
    
    print_color $BLUE "🔒 Obtaining SSL certificate..."
    certbot --nginx -d ${PORTAINER_DOMAIN} --email ${SSL_EMAIL} --agree-tos --non-interactive --redirect
    
    # Final HTTPS configuration
    cat > /etc/nginx/sites-available/${PORTAINER_DOMAIN} << EOF
server {
    listen 80;
    server_name ${PORTAINER_DOMAIN};
    return 301 https://\$server_name\$request_uri;
}

server {
    listen 443 ssl http2;
    server_name ${PORTAINER_DOMAIN};

    ssl_certificate /etc/letsencrypt/live/${PORTAINER_DOMAIN}/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/${PORTAINER_DOMAIN}/privkey.pem;
    
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers off;
    ssl_session_timeout 1d;

    add_header Strict-Transport-Security "max-age=31536000" always;
    add_header X-Content-Type-Options nosniff;
    add_header X-Frame-Options SAMEORIGIN;
    add_header X-XSS-Protection "1; mode=block";

    access_log /var/log/nginx/${PORTAINER_DOMAIN}_access.log;
    error_log /var/log/nginx/${PORTAINER_DOMAIN}_error.log;

    client_max_body_size 1G;
    proxy_connect_timeout 300s;
    proxy_send_timeout 300s;
    proxy_read_timeout 300s;

    location / {
        proxy_pass http://127.0.0.1:${PORTAINER_PORT};
        proxy_set_header Host \$http_host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_set_header X-Forwarded-Host \$server_name;
        proxy_redirect off;
        
        # WebSocket support for real-time updates
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        
        # Disable buffering for real-time logs
        proxy_buffering off;
        proxy_request_buffering off;
    }

    # API endpoint
    location /api/ {
        proxy_pass http://127.0.0.1:${PORTAINER_PORT};
        proxy_set_header Host \$http_host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_redirect off;
        
        # API specific timeouts
        proxy_read_timeout 300s;
        proxy_send_timeout 300s;
    }

    # Static assets
    location ~* \.(css|js|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)\$ {
        proxy_pass http://127.0.0.1:${PORTAINER_PORT};
        proxy_set_header Host \$http_host;
        
        expires 1d;
        add_header Cache-Control "public";
    }
}
EOF

    nginx -t && systemctl reload nginx
    print_color $GREEN "✅ Nginx configured with SSL"
}

create_management_script() {
    print_color $BLUE "📝 Creating management script..."
    cat > /opt/portainer/manage-portainer.sh << 'EOF'
#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

case "$1" in
    start)
        echo "Starting Portainer..."
        docker-compose up -d
        ;;
    stop)
        echo "Stopping Portainer..."
        docker-compose down
        ;;
    restart)
        echo "Restarting Portainer..."
        docker-compose restart
        ;;
    logs)
        echo "Showing Portainer logs..."
        docker-compose logs -f portainer
        ;;
    status)
        echo "Portainer status:"
        docker-compose ps
        echo
        echo "Service URLs:"
        echo "Portainer Web: https://$(grep PORTAINER_DOMAIN .env | cut -d= -f2)/"
        echo "Admin Username: admin"
        echo "Admin Password: $(grep ADMIN_PASSWORD .env | cut -d= -f2)"
        ;;
    backup)
        echo "Creating backup..."
        tar -czf "portainer-backup-$(date +%Y%m%d-%H%M%S).tar.gz" portainer-data
        echo "Backup created"
        ;;
    update)
        echo "Updating Portainer..."
        docker-compose pull
        docker-compose up -d
        ;;
    reset-password)
        echo "Generating new admin password..."
        NEW_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-16)
        HASHED_PASSWORD=$(htpasswd -bnBC 10 "" "$NEW_PASSWORD" | tr -d ':\n' | sed 's/\$2y/\$2a/')
        echo "$HASHED_PASSWORD" > portainer-data/admin_password
        sed -i "s/ADMIN_PASSWORD=.*/ADMIN_PASSWORD=${NEW_PASSWORD}/" .env
        docker-compose restart
        echo "New admin password: $NEW_PASSWORD"
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|logs|status|backup|update|reset-password}"
        exit 1
        ;;
esac
EOF

    chmod +x /opt/portainer/manage-portainer.sh
}

# Main installation flow
main() {
    print_banner
    check_prerequisites
    get_configuration
    install_portainer
    configure_nginx
    create_management_script
    
    print_color $GREEN "✅ Portainer installation completed!"
    echo
    print_color $CYAN "======================================"
    print_color $CYAN "    Installation Complete!"
    print_color $CYAN "======================================"
    echo
    print_color $YELLOW "📍 Access Information:"
    print_color $BLUE "   URL: https://${PORTAINER_DOMAIN}"
    print_color $BLUE "   Username: admin"
    print_color $BLUE "   Password: ${ADMIN_PASSWORD}"
    print_color $BLUE "   Edge Port: ${PORTAINER_EDGE_PORT}"
    echo
    print_color $YELLOW "🔧 Management Commands:"
    print_color $BLUE "   /opt/portainer/manage-portainer.sh start"
    print_color $BLUE "   /opt/portainer/manage-portainer.sh stop"
    print_color $BLUE "   /opt/portainer/manage-portainer.sh restart"
    print_color $BLUE "   /opt/portainer/manage-portainer.sh logs"
    print_color $BLUE "   /opt/portainer/manage-portainer.sh status"
    print_color $BLUE "   /opt/portainer/manage-portainer.sh backup"
    print_color $BLUE "   /opt/portainer/manage-portainer.sh reset-password"
    echo
    print_color $YELLOW "📁 Configuration Location:"
    print_color $BLUE "   /opt/portainer/"
    echo
    print_color $YELLOW "🔧 Important Notes:"
    print_color $BLUE "   • Save the admin password shown above"
    print_color $BLUE "   • You can reset the password using the management script"
    print_color $BLUE "   • Portainer manages all Docker containers on this system"
    print_color $BLUE "   • Access logs and container management through the web interface"
    echo
    print_color $GREEN "🌐 Access Portainer at: https://${PORTAINER_DOMAIN}"
    print_color $GREEN "👤 Login with: admin / ${ADMIN_PASSWORD}"
}

# Run main function
main "$@"
