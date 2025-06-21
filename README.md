# Portainer Docker Installation Script

![Portainer Logo](https://www.portainer.io/hubfs/Brand%20Assets/Logos/Portainer%20Logo%20Solid%20All%20-%20Blue%20no%20padding.svg)

A comprehensive automated installation script for deploying Portainer container management platform with Docker, Nginx reverse proxy, and SSL certificates.

## 🚀 Features

- **Automated Installation**: Complete Portainer deployment with minimal user input
- **Docker-based**: Uses official Portainer CE Docker image for easy management
- **SSL/HTTPS Support**: Automatic SSL certificate generation with Let's Encrypt
- **Nginx Reverse Proxy**: Professional web server configuration with security headers
- **Secure Authentication**: Auto-generated admin password with bcrypt hashing
- **Management Scripts**: Built-in scripts for easy maintenance and container management
- **Security Hardened**: Includes security best practices and WebSocket support
- **Container Management**: Full Docker container lifecycle management through web UI
- **Real-time Monitoring**: Live container logs, stats, and resource monitoring

## 📋 Prerequisites

### System Requirements
- **OS**: Ubuntu 18.04+ / Debian 10+ / CentOS 7+
- **RAM**: Minimum 1GB (recommended 2GB+)
- **Disk Space**: Minimum 5GB free space
- **Network**: Public IP address with domain pointing to it
- **Privileges**: Root access or sudo privileges

### Required Ports
- **80**: HTTP (for SSL certificate validation)
- **443**: HTTPS (Nginx reverse proxy)
- **9000**: Portainer Main Interface (localhost only)
- **8000**: Portainer Edge Agent Port (configurable)

## 🛠 Installation

### Quick Start

1. **Clone the repository**:
   ```bash
   git clone https://github.com/defendx1/Portainer.git
   cd Portainer
   chmod +x install-portainer.sh
   ```

   **Or download directly**:
   ```bash
   wget https://raw.githubusercontent.com/defendx1/Portainer/main/install-portainer.sh
   chmod +x install-portainer.sh
   ```

2. **Run the installation**:
   ```bash
   sudo ./install-portainer.sh
   ```

3. **Follow the prompts**:
   - Enter your domain name (e.g., `portainer.yourdomain.com`)
   - Provide email for SSL certificate
   - Script auto-generates secure admin password

### Manual Installation Steps

The script automatically handles:
- ✅ Docker and Docker Compose installation
- ✅ Nginx web server installation
- ✅ Certbot for SSL certificates
- ✅ System requirements validation
- ✅ Port conflict resolution
- ✅ Directory structure creation
- ✅ Docker Compose configuration
- ✅ Secure password generation
- ✅ SSL certificate generation
- ✅ Nginx reverse proxy setup

## 🔧 Configuration

### Default Credentials
- **Username**: `admin`
- **Password**: Auto-generated (displayed after installation)
- **⚠️ Important**: Save the generated password or use the reset function

### Docker Services
The installation creates the following container:
- `portainer`: Portainer CE container management platform

### File Structure
```
/opt/portainer/
├── docker-compose.yml      # Main Docker Compose configuration
├── .env                    # Environment variables
├── manage-portainer.sh     # Management script
├── portainer-data/         # Portainer data persistence
│   └── admin_password      # Hashed admin password
└── portainer-ssl/          # SSL certificates (if needed)
```

## 🎮 Management Commands

Use the built-in management script for easy operations:

```bash
cd /opt/portainer

# Start Portainer
./manage-portainer.sh start

# Stop Portainer
./manage-portainer.sh stop

# Restart Portainer
./manage-portainer.sh restart

# View logs
./manage-portainer.sh logs

# Check status and display credentials
./manage-portainer.sh status

# Create backup
./manage-portainer.sh backup

# Update Portainer
./manage-portainer.sh update

# Reset admin password
./manage-portainer.sh reset-password
```

## 🔐 Security Features

### SSL/TLS Configuration
- **TLS 1.2/1.3** support only
- **HSTS** (HTTP Strict Transport Security) headers
- **Security headers**: X-Content-Type-Options, X-Frame-Options, X-XSS-Protection
- **Automatic HTTP to HTTPS** redirection

### Authentication Security
- **Bcrypt password hashing** (cost factor 10)
- **Auto-generated secure passwords** (16 characters)
- **Password reset functionality** via management script

### Network Security
- Portainer accessible only through Nginx proxy
- WebSocket support for real-time features
- Configurable port assignments to avoid conflicts

## 🐳 Container Management Features

### Web Interface Capabilities

1. **Container Management**:
   - Start, stop, restart containers
   - View real-time logs and statistics
   - Execute commands inside containers
   - Manage container networks and volumes

2. **Image Management**:
   - Pull images from registries
   - Build images from Dockerfiles
   - Manage image tags and repositories

3. **Volume & Network Management**:
   - Create and manage Docker volumes
   - Configure custom networks
   - Network isolation and security

4. **Stack Deployment**:
   - Deploy Docker Compose stacks
   - Template management
   - Environment variable configuration

### Advanced Features
- **Multi-environment support**: Manage multiple Docker endpoints
- **User management**: Create teams and assign permissions
- **Registry management**: Connect to private Docker registries
- **Resource monitoring**: CPU, memory, network usage tracking

## 🔄 Backup and Restore

### Automated Backup
```bash
./manage-portainer.sh backup
```
Creates timestamped backup including:
- Portainer database and settings
- Container configurations
- User accounts and permissions

### Manual Backup
```bash
# Backup Portainer data
tar -czf portainer-backup-$(date +%Y%m%d).tar.gz /opt/portainer/portainer-data/

# Full system backup
docker run --rm -v /opt/portainer/portainer-data:/source -v $(pwd):/backup alpine tar czf /backup/portainer-full-backup.tar.gz -C /source .
```

### Restore Process
```bash
# Stop Portainer
./manage-portainer.sh stop

# Restore data
tar -xzf portainer-backup.tar.gz -C /opt/portainer/

# Start Portainer
./manage-portainer.sh start
```

## 🚨 Troubleshooting

### Common Issues

**1. Portainer won't start**
```bash
# Check logs
./manage-portainer.sh logs

# Check Docker daemon
systemctl status docker

# Verify port availability
netstat -tlnp | grep :9000
```

**2. SSL certificate issues**
```bash
# Renew certificate
certbot renew --nginx

# Check certificate status
certbot certificates
```

**3. Login issues**
```bash
# Reset admin password
./manage-portainer.sh reset-password

# Check password file
cat /opt/portainer/portainer-data/admin_password
```

**4. WebSocket connection errors**
```bash
# Check Nginx configuration
nginx -t

# Restart Nginx
systemctl restart nginx
```

### Log Locations
- **Portainer**: `docker logs portainer`
- **Nginx**: `/var/log/nginx/`
- **System**: `/var/log/syslog`

## 🔄 Updates and Maintenance

### Update Portainer
```bash
cd /opt/portainer
./manage-portainer.sh update
```

### SSL Certificate Renewal
Certificates auto-renew via cron. Manual renewal:
```bash
certbot renew --nginx
systemctl reload nginx
```

### System Maintenance
```bash
# Clean up unused Docker resources
docker system prune -f

# Update system packages
apt update && apt upgrade -y

# Check disk space
df -h /opt/portainer/
```

## 📊 Performance Tuning

### Docker Configuration
Edit `/etc/docker/daemon.json`:
```json
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "storage-driver": "overlay2"
}
```

### Nginx Optimization
For high-traffic environments, adjust in Nginx config:
```nginx
client_max_body_size 5G;
proxy_connect_timeout 600s;
proxy_send_timeout 600s;
proxy_read_timeout 600s;
```

## 🔧 Advanced Configuration

### Custom Environment Variables
Edit `/opt/portainer/.env`:
```bash
PORTAINER_DOMAIN=your-domain.com
PORTAINER_PORT=9000
PORTAINER_EDGE_PORT=8000
```

### Multi-Environment Setup
Configure additional Docker endpoints through Portainer UI:
1. Go to Settings → Endpoints
2. Add endpoint (local or remote)
3. Configure connection details

## 🆘 Support and Resources

### Project Resources
- **GitHub Repository**: [https://github.com/defendx1/Portainer](https://github.com/defendx1/Portainer)
- **Issues & Support**: [Report Issues](https://github.com/defendx1/Portainer/issues)
- **Latest Releases**: [View Releases](https://github.com/defendx1/Portainer/releases)

### Official Documentation
- [Portainer Documentation](https://docs.portainer.io/)
- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Reference](https://docs.docker.com/compose/)
- [Nginx Documentation](https://nginx.org/en/docs/)

### Community Support
- [Portainer Community](https://www.portainer.io/community)
- [Docker Community Forum](https://forums.docker.com/)
- [DefendX1 Telegram](https://t.me/defendx1)

## 📄 License

This script is provided under the MIT License. See LICENSE file for details.

---

## 👨‍💻 Author & Contact

**Script Developer**: DefendX1 Team  
**Website**: [https://defendx1.com/](https://defendx1.com/)  
**Telegram**: [t.me/defendx1](https://t.me/defendx1)

### About DefendX1
DefendX1 specializes in cybersecurity solutions, infrastructure automation, and container management systems. Visit [defendx1.com](https://defendx1.com/) for more security tools and DevOps resources.

---

## 🔗 Resources & Links

### Project Resources
- **GitHub Repository**: [https://github.com/defendx1/Portainer](https://github.com/defendx1/Portainer)
- **Issues & Support**: [Report Issues](https://github.com/defendx1/Portainer/issues)
- **Latest Releases**: [View Releases](https://github.com/defendx1/Portainer/releases)

### Download & Installation
**GitHub Repository**: [https://github.com/defendx1/Portainer](https://github.com/defendx1/Portainer)

Clone or download the latest version:
```bash
git clone https://github.com/defendx1/Portainer.git
```

## 🤝 Contributing

Contributions are welcome! Please:
1. Fork the repository: [https://github.com/defendx1/Portainer](https://github.com/defendx1/Portainer)
2. Create a feature branch
3. Submit a pull request

## ⭐ Star This Project

If this script helped you, please consider starring the repository at [https://github.com/defendx1/Portainer](https://github.com/defendx1/Portainer)!

---

**Last Updated**: June 2025  
**Version**: 1.0.0
