FROM ubuntu:22.04

LABEL maintainer="IPTV System <admin@iptv.com>"
LABEL version="2.0.0"
LABEL description="Xtream Codes IPTV System with Koyeb PostgreSQL"

ENV DEBIAN_FRONTEND=noninteractive \
    TZ=UTC \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8

# تحديث النظام وتثبيت الاعتمادات
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

# إضافة مستودعات PHP
RUN add-apt-repository ppa:ondrej/php -y && \
    apt-get update

# تثبيت PHP وملحقاته
RUN apt-get install -y \
    php8.1 \
    php8.1-cli \
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
    && rm -rf /var/lib/apt/lists/*

# تثبيت Nginx
RUN apt-get update && apt-get install -y nginx && \
    rm -rf /var/lib/apt/lists/*

# تثبيت PostgreSQL Client
RUN apt-get update && apt-get install -y postgresql-client && \
    rm -rf /var/lib/apt/lists/*

# إنشاء مستخدم Xtream Codes
RUN useradd -m -s /bin/bash xtream && \
    usermod -aG www-data xtream

# إنشاء المجلدات الأساسية
RUN mkdir -p /home/xtreamcodes/iptv_xtream_codes && \
    mkdir -p /home/xtreamcodes/iptv_xtream_codes/{logs,tmp,backups,wwwdir} && \
    chown -R xtream:xtream /home/xtreamcodes && \
    chmod -R 755 /home/xtreamcodes

# نسخ ملفات التهيئة
COPY config/xtreamui_install.sh /tmp/install.sh
COPY config/nginx_xtream.conf /etc/nginx/sites-available/xtream
COPY config/start.sh /start.sh

# تعيين الأذونات
RUN chmod +x /tmp/install.sh /start.sh && \
    chmod 755 /start.sh

# فتح المنافذ
EXPOSE 80 443 1935 25461 25462 25500 8080 8000-8010

# الصحة (Health Check)
HEALTHCHECK --interval=30s --timeout=10s --retries=3 \
    CMD curl -f http://localhost:25500/ || exit 1

# نقطة الدخول
ENTRYPOINT ["/start.sh"]
CMD ["xtream"]
