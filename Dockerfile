FROM php:8.2-apache

# System libraries + PHP extensions required by ChurchCRM
RUN apt-get update && apt-get install -y \
    libpng-dev \
    libjpeg-dev \
    libonig-dev \
    libxml2-dev \
    libzip-dev \
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

# Install Composer safely (no apt, no PHP conflicts)
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Copy application
COPY . /var/www/html

# Run Composer where ChurchCRM expects it
WORKDIR /var/www/html/src
RUN composer install --no-dev --no-interaction --prefer-dist

# Apache vhost points to /src
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
CMD ["apache2-foreground"]
