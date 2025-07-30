#!/bin/bash
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
echo "Starting user-data script execution at $(date)"

# Update system
dnf update -y

# Install Node.js 18.x using NodeSource repository (Amazon Linux 2023)
echo "Installing Node.js..."
curl -fsSL https://rpm.nodesource.com/setup_18.x | bash -
dnf install -y nodejs

# Verify Node.js installation
echo "Node.js version: $(node --version)"
echo "NPM version: $(npm --version)"

# Ensure npm is properly installed and update to latest version
if ! command -v npm &> /dev/null; then
    echo "NPM not found, installing manually..."
    dnf install -y npm
fi

npm install -g npm@latest

# Install SQLite and other dependencies
dnf install -y sqlite amazon-ssm-agent

# Start and enable SSM agent
systemctl start amazon-ssm-agent
systemctl enable amazon-ssm-agent

# Create application directory
mkdir -p /opt/bot-trapper
cd /opt/bot-trapper

# Create deploy script
cat > /opt/bot-trapper/deploy_web.sh << 'EOF'
#!/bin/bash
set -e
exec > >(tee /var/log/deploy-web.log) 2>&1
echo "Starting deploy script at $(date)"

cd /opt/bot-trapper

# Download website files from S3
echo "Downloading website files from S3..."
aws s3 sync s3://${website_bucket_name}/ ./website/ --delete
echo "S3 sync completed"

# Check if website directory exists and has files
if [ ! -d "./website" ]; then
    echo "ERROR: Website directory not found after S3 sync"
    exit 1
fi

if [ ! -f "./website/package.json" ]; then
    echo "ERROR: package.json not found in website directory"
    exit 1
fi

# Install dependencies
echo "Installing npm dependencies..."
cd website
npm install --production
echo "NPM install completed"

# Initialize SQLite database
echo "Initializing SQLite database..."
sqlite3 comments.db << 'SQL'
CREATE TABLE IF NOT EXISTS tbl_comments (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    commenter TEXT NOT NULL,
    details TEXT NOT NULL,
    silent_discard BOOLEAN DEFAULT 0,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
SQL
echo "Database initialized"

echo "Deploy script completed at $(date)"
EOF

chmod +x /opt/bot-trapper/deploy_web.sh

# Run deploy script
echo "Running deploy script..."
/opt/bot-trapper/deploy_web.sh

# Get the actual Node.js path
NODE_PATH=$(which node)
echo "Node.js path: $NODE_PATH"

# Create systemd service for auto-start
cat > /etc/systemd/system/bot-trapper.service << EOF
[Unit]
Description=Bot Trapper Web Application
After=network.target
Wants=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/bot-trapper/website
ExecStart=$NODE_PATH server.js
Restart=always
RestartSec=10
Environment=NODE_ENV=production
Environment=PATH=/usr/local/bin:/usr/bin:/bin
StandardOutput=journal
StandardError=journal
SyslogIdentifier=bot-trapper

[Install]
WantedBy=multi-user.target
EOF

# Enable and start the service
echo "Setting up systemd service..."
systemctl daemon-reload
systemctl enable bot-trapper.service
systemctl start bot-trapper.service

# Wait a moment and check service status
sleep 5
systemctl status bot-trapper.service --no-pager

# Create log rotation
cat > /etc/logrotate.d/bot-trapper << 'EOF'
/var/log/bot-trapper.log {
    daily
    missingok
    rotate 7
    compress
    notifempty
    create 644 root root
}
EOF

echo "User-data script completed at $(date)"
