FROM php:8.2-apache

# Install system dependencies and PHP extensions required by ChurchCRM
RUN apt-get update && apt-get install -y \
    libpng-dev \
    libjpeg-dev \
    libonig-dev \
    libxml2-dev \
    libzip-dev \
    zip \
    unzip \
    git \
 && docker-php-ext-install \
    pdo \
    pdo_mysql \
    mysqli \
    gd \
    zip \
 && rm -rf /var/lib/apt/lists/*

# Enable Apache modules
RUN a2enmod rewrite

# Enforce single Apache MPM at runtime
RUN printf '%s\n' \
  '#!/bin/sh' \
  'set -e' \
  '' \
  'rm -f /etc/apache2/mods-enabled/mpm_*.load /etc/apache2/mods-enabled/mpm_*.conf || true' \
  'a2enmod mpm_prefork >/dev/null 2>&1 || true' \
  'a2dismod mpm_event mpm_worker >/dev/null 2>&1 || true' \
  'exec apache2-foreground' \
  > /usr/local/bin/railway-start \
 && chmod +x /usr/local/bin/railway-start

# Configure Apache vhost explicitly for ChurchCRM
RUN printf '%s\n' \
  '<VirtualHost *:80>' \
  '  DocumentRoot /var/www/html' \
  '  DirectoryIndex index.php index.html' \
  '  <Directory /var/www/html>' \
  '    AllowOverride All' \
  '    Require all granted' \
  '  </Directory>' \
  '</VirtualHost>' \
  > /etc/apache2/sites-available/000-default.conf

# Copy application
COPY . /var/www/html
WORKDIR /var/www/html

# Permissions
RUN chown -R www-data:www-data /var/www/html \
 && chmod -R 755 /var/www/html

EXPOSE 80

CMD ["/usr/local/bin/railway-start"]
