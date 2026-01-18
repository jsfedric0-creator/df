FROM ubuntu:22.04

LABEL maintainer="IPTV System <admin@iptv.com>"
LABEL version="2.0.0"
LABEL description="Xtream Codes IPTV System with Koyeb PostgreSQL"

ENV DEBIAN_FRONTEND=noninteractive \
    TZ=UTC \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8

# تحديث النظام وتثبيت الاعتمادات الأساسية
RUN apt-get update && apt-get upgrade -y && \
    apt-get install -y \
    wget \
    curl \
    gnupg \
    lsb-release \
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# إضافة مستودعات PHP (Ondřej Surý PPA)
RUN LC_ALL=C.UTF-8 add-apt-repository ppa:ondrej/php -y && \
    apt-get update

# تثبيت PHP 8.1 وملحقاته
RUN apt-get update && apt-get install -y \
    php8.1 \
    php8.1-cli \
    php8.1-fpm \
    php8.1-common \
    php8.1-curl \
    php8.1-gd \
    php8.1-mysql \
    php8.1-pgsql \
    php8.1-mbstring \
    php8.1-xml \
    php8.1-zip \
    php8.1-bcmath \
    php8.1-json \
    php8.1-soap \
    php8.1-intl \
    php8.1-imagick \
    php8.1-opcache \
    && rm -rf /var/lib/apt/lists/*

# تثبيت Nginx
RUN apt-get update && apt-get install -y nginx && \
    rm -rf /var/lib/apt/lists/*

# تثبيت PostgreSQL Client
RUN apt-get update && apt-get install -y postgresql-client postgresql-common && \
    rm -rf /var/lib/apt/lists/*

# تثبيت أدوات إضافية
RUN apt-get update && apt-get install -y \
    ffmpeg \
    mediainfo \
    git \
    unzip \
    nano \
    htop \
    net-tools \
    iptables \
    cron \
    supervisor \
    && rm -rf /var/lib/apt/lists/*

# إنشاء مستخدم Xtream Codes
RUN useradd -m -s /bin/bash xtream && \
    usermod -aG www-data xtream

# إنشاء المجلدات الأساسية
RUN mkdir -p /home/xtreamcodes/iptv_xtream_codes && \
    mkdir -p /home/xtreamcodes/iptv_xtream_codes/{logs,tmp,backups,wwwdir,config,cache} && \
    chown -R xtream:xtream /home/xtreamcodes && \
    chmod -R 755 /home/xtreamcodes

# إنشاء مجلدات البث
RUN mkdir -p /opt/streams/{hls,dash,vod,rec} && \
    chown -R www-data:www-data /opt/streams && \
    chmod -R 755 /opt/streams

# نسخ ملفات التهيئة
COPY config/xtreamui_install.sh /tmp/install.sh
COPY config/nginx_xtream.conf /etc/nginx/sites-available/xtream
COPY config/start.sh /start.sh
COPY config/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# تكوين PHP-FPM
RUN mv /etc/php/8.1/fpm/pool.d/www.conf /etc/php/8.1/fpm/pool.d/www.conf.backup && \
    echo '[xtream]\n\
user = xtream\n\
group = xtream\n\
listen = /run/php/php8.1-fpm-xtream.sock\n\
listen.owner = www-data\n\
listen.group = www-data\n\
pm = dynamic\n\
pm.max_children = 50\n\
pm.start_servers = 5\n\
pm.min_spare_servers = 5\n\
pm.max_spare_servers = 35\n\
pm.max_requests = 500\n\
chdir = /\n' > /etc/php/8.1/fpm/pool.d/xtream.conf

# تكوين Nginx
RUN rm -f /etc/nginx/sites-enabled/default && \
    ln -sf /etc/nginx/sites-available/xtream /etc/nginx/sites-enabled/

# تكوين PHP
RUN sed -i 's/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/' /etc/php/8.1/fpm/php.ini && \
    sed -i 's/max_execution_time = 30/max_execution_time = 300/' /etc/php/8.1/fpm/php.ini && \
    sed -i 's/memory_limit = 128M/memory_limit = 512M/' /etc/php/8.1/fpm/php.ini && \
    sed -i 's/upload_max_filesize = 2M/upload_max_filesize = 100M/' /etc/php/8.1/fpm/php.ini && \
    sed -i 's/post_max_size = 8M/post_max_size = 100M/' /etc/php/8.1/fpm/php.ini

# تعيين الأذونات
RUN chmod +x /tmp/install.sh /start.sh && \
    chmod 755 /start.sh

# إنشاء مجلدات السجلات
RUN mkdir -p /var/log/{nginx,php8.1-fpm,supervisor} && \
    chown -R www-data:www-data /var/log/{nginx,php8.1-fpm,supervisor}

# فتح المنافذ
EXPOSE 80 443 1935 25461 25462 25500 8080 8001

# الصحة (Health Check)
HEALTHCHECK --interval=30s --timeout=10s --retries=3 \
    CMD curl -f http://localhost/ || exit 1

# نقطة الدخول
ENTRYPOINT ["/start.sh"]
CMD ["supervisord", "-n", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
