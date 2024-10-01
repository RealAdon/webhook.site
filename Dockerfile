##############################################
# Stage 1: Install node dependencies and run gulp
##############################################
FROM --platform=linux/arm64 node:11 as npm
WORKDIR /app

COPY package.json /app
COPY package-lock.json /app
RUN npm install

COPY resources /app/resources
COPY gulpfile.js /app
RUN npm run gulp

##############################################
# Stage 2: Composer, PHP-FPM, and NGINX (ARM64)
##############################################
FROM arm64v8/php:7.3-fpm
WORKDIR /var/www/html

# Install NGINX on ARM64
RUN apt-get update && apt-get install -y nginx

# Contains laravel echo server proxy configuration
COPY /nginx.conf /etc/nginx/conf.d

USER www-data

ADD --chown=www-data:www-data /composer.json /var/www/html
ADD --chown=www-data:www-data /composer.lock /var/www/html

RUN composer install --no-interaction --no-autoloader --no-dev --prefer-dist --no-scripts \
    && rm -rf /home/www-data/.composer/cache

ADD --chown=www-data:www-data /storage /var/www/html/storage
ADD --chown=www-data:www-data /bootstrap /var/www/html/bootstrap
ADD --chown=www-data:www-data /public /var/www/html/public
ADD --chown=www-data:www-data /artisan /var/www/html
ADD --chown=www-data:www-data /database /var/www/html/database
ADD --chown=www-data:www-data /config /var/www/html/config
ADD --chown=www-data:www-data /app /var/www/html/app

RUN composer dump-autoload --optimize --no-dev \
    && touch /var/www/html/database/database.sqlite \
    && php artisan optimize \
    && php artisan migrate

ADD --chown=www-data:www-data /resources /var/www/html/resources
COPY --chown=www-data:www-data --from=npm /app/public/css /var/www/html/public/css
COPY --chown=www-data:www-data --from=npm /app/public/js /var/www/html/public/js

USER root
