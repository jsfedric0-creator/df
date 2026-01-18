server {
    listen 80;
    listen [::]:80;
    server_name _;
    
    root /home/xtreamcodes/iptv_xtream_codes/wwwdir;
    index index.php index.html index.htm;
    
    access_log /var/log/nginx/xtream_access.log;
    error_log /var/log/nginx/xtream_error.log;
    
    client_max_body_size 100M;
    
    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }
    
    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php8.1-fpm.sock;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
        
        fastcgi_buffer_size 128k;
        fastcgi_buffers 256 16k;
        fastcgi_busy_buffers_size 256k;
        fastcgi_temp_file_write_size 256k;
    }
    
    # Xtream Codes API endpoints
    location ~ ^/(player_api|panel_api)\.php$ {
        fastcgi_pass unix:/var/run/php/php8.1-fpm.sock;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
        
        fastcgi_read_timeout 300;
        fastcgi_send_timeout 300;
        
        # إعدادات CORS
        add_header 'Access-Control-Allow-Origin' '*' always;
        add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS' always;
        add_header 'Access-Control-Allow-Headers' 'DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range' always;
        add_header 'Access-Control-Expose-Headers' 'Content-Length,Content-Range' always;
        
        if ($request_method = 'OPTIONS') {
            add_header 'Access-Control-Max-Age' 1728000;
            add_header 'Content-Type' 'text/plain; charset=utf-8';
            add_header 'Content-Length' 0;
            return 204;
        }
    }
    
    # حماية الملفات الحساسة
    location ~ /\.(ht|git|svn) {
        deny all;
    }
    
    location ~ /\. {
        deny all;
        access_log off;
        log_not_found off;
    }
    
    # تقديم الملفات الثابتة بشكل أفضل
    location ~* \.(jpg|jpeg|png|gif|ico|css|js|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
        access_log off;
    }
    
    # إعدادات الأمان
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
    
    # تعطيل إظهار إصدار Nginx
    server_tokens off;
    
    # تعطيل أنواع MIME غير الآمنة
    location ~* \.(?:bak|conf|dist|fla|in[ci]|log|orig|sh|sql|sw[op]|txt)$ {
        deny all;
    }
}
