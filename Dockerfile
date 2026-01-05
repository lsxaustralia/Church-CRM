FROM php:8.2-apache

# System dependencies and PHP extensions
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

# Install Composer correctly
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Enable Apache modules
RUN a2enmod rewrite

# Enforce single Apache MPM at runtime
RUN printf '%s\n' \
  '#!/bin/sh' \
  'set -e' \
  'rm -f /etc/apache2/mods-enabled/mpm_*.load /etc/apache2/mods-enabled/mpm_*.conf || true' \
  'a2enmod mpm_prefork >/dev/null 2>&1 || true' \
  'a2dismod mpm_event mpm_worker >/dev/null 2>&1 || true' \
  'exec apache2-foreground' \
  > /usr/local/bin/railway-start \
 && chmod +x /usr/local/bin/railway-start

# Copy app
COPY . /var/www/html
WORKDIR /var/www/html

# Install Composer deps INTO src/vendor (critical)
RUN composer install \
    --no-dev \
    --no-interaction \
    --prefer-dist \
    --working-dir=/var/www/html/src

# Apache vhost, ChurchCRM runs from /src
RUN printf '%s\n' \
  '<VirtualHost *:80>' \
  '  DocumentRoot /var/www/html/src' \
  '  DirectoryIndex index.php index.html' \
  '  <Directory /var/www/html/src>' \
  '    AllowOverride All' \
  '    Require all granted' \
  '  </Directory>' \
  '</VirtualHost>' \
  > /etc/apache2/sites-available/000-default.conf

# Permissions
RUN chown -R www-data:www-data /var/www/html \
 && chmod -R 755 /var/www/html

EXPOSE 80
CMD ["/usr/local/bin/railway-start"]
