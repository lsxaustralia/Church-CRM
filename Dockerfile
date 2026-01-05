FROM php:8.2-apache

# System deps, PHP extensions needed by ChurchCRM
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

# Apache modules ChurchCRM commonly needs
RUN a2enmod rewrite

# Enforce exactly one Apache MPM at runtime
# This prevents "More than one MPM loaded" even if something enables extra MPMs during image build
RUN printf '%s\n' \
  '#!/bin/sh' \
  'set -e' \
  '' \
  '# Remove any enabled MPMs' \
  'rm -f /etc/apache2/mods-enabled/mpm_*.load /etc/apache2/mods-enabled/mpm_*.conf || true' \
  '' \
  '# Enable prefork MPM, required for mod_php in php:apache images' \
  'a2enmod mpm_prefork >/dev/null 2>&1 || true' \
  'a2dismod mpm_event mpm_worker >/dev/null 2>&1 || true' \
  '' \
  '# Start Apache in foreground' \
  'exec apache2-foreground' \
  > /usr/local/bin/railway-start \
  && chmod +x /usr/local/bin/railway-start

# App code
COPY . /var/www/html
WORKDIR /var/www/html

RUN chown -R www-data:www-data /var/www/html \
  && chmod -R 755 /var/www/html

EXPOSE 80

CMD ["/usr/local/bin/railway-start"]
