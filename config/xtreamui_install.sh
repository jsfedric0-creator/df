#!/bin/bash

echo "Installing Xtream UI..."

# التحديثات
apt-get update
apt-get upgrade -y

# تثبيت الاعتمادات
apt-get install -y \
    wget \
    curl \
    unzip \
    nano \
    htop \
    net-tools

# تنزيل Xtream UI
cd /tmp
wget -O xtreamui.zip https://github.com/xtreamui/xtreamui/releases/latest/download/xtreamui.zip
unzip xtreamui.zip -d /home/xtreamcodes/iptv_xtream_codes/

# تعيين الأذونات
chown -R xtream:xtream /home/xtreamcodes
chmod -R 755 /home/xtreamcodes

# تكوين قاعدة البيانات
echo "Configuring PostgreSQL connection..."
cat > /home/xtreamcodes/iptv_xtream_codes/config/database.php << EOF
<?php
return [
    'default' => 'pgsql',
    'connections' => [
        'pgsql' => [
            'driver' => 'pgsql',
            'host' => '${DB_HOST}',
            'port' => '${DB_PORT}',
            'database' => '${DB_NAME}',
            'username' => '${DB_USER}',
            'password' => '${DB_PASS}',
            'charset' => 'utf8',
            'prefix' => '',
            'schema' => 'public',
        ],
    ],
];
EOF

# تكوين Nginx
cat > /etc/nginx/sites-available/xtream << EOF
server {
    listen 80;
    listen [::]:80;
    server_name ${SERVER_IP};
    
    root /home/xtreamcodes/iptv_xtream_codes/wwwdir;
    index index.php index.html;
    
    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }
    
    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php8.1-fpm.sock;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
    }
    
    location ~ /\.ht {
        deny all;
    }
    
    # Xtream API
    location /player_api.php {
        fastcgi_pass unix:/var/run/php/php8.1-fpm.sock;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME \$document_root/player_api.php;
    }
}
EOF

# تفعيل الموقع
ln -sf /etc/nginx/sites-available/xtream /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# إعادة تشغيل الخدمات
systemctl restart nginx
systemctl restart php8.1-fpm

echo "Installation completed!"
