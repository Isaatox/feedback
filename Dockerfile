# Étape 1 : Build avec Composer
FROM php:8.1-cli as builder

# Install system deps
RUN apt-get update && apt-get install -y \
    unzip libpng-dev libjpeg-dev libfreetype6-dev git zip libicu-dev libonig-dev \
    && docker-php-ext-install intl gd pdo pdo_mysql opcache

# Installe Composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Copie du code et installation des dépendances
WORKDIR /app
COPY . .
RUN composer install --no-dev --optimize-autoloader --no-scripts

# Étape 2 : Apache avec PHP 8.1 + mod_rewrite
FROM php:8.1-apache

# Active mod_rewrite
RUN a2enmod rewrite

# Même extensions que dans builder
RUN apt-get update && apt-get install -y \
    libpng-dev libjpeg-dev libfreetype6-dev libicu-dev libonig-dev unzip \
    && docker-php-ext-install intl gd pdo pdo_mysql opcache

# Répertoire de travail
WORKDIR /var/www/html

# Copier les fichiers Symfony et vendor depuis le builder
COPY --from=builder /app /var/www/html

# Symfony est servi depuis /public
ENV APACHE_DOCUMENT_ROOT=/var/www/html/public
RUN sed -ri -e 's!/var/www/html!/var/www/html/public!g' /etc/apache2/sites-available/*.conf
RUN sed -ri -e 's!/var/www/!/var/www/html/public!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf

# Variables d’environnement (en production, met-les dans Render)
ENV APP_ENV=prod
