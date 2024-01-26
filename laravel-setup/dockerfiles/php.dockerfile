FROM php:8.3-fpm-alpine

WORKDIR /var/www/html

COPY src .

RUN docker-php-ext-install pdo pdo_mysql

RUN chown -R www-data:www-data /var/www/html

# Base image exports port 9000 to listen to
# If there's no CMD at the end, it will run the default CMD of the base image