# Базовый образ
FROM php:8.2-apache

# Установка необходимых зависимостей
RUN apt-get update && apt-get install -y \
    git \
    unzip \
    libzip-dev \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    libonig-dev \
    libxml2-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install gd pdo_mysql zip mbstring xml

# Установка Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Настройка Apache
COPY . /var/www/html/
RUN chown -R www-data:www-data /var/www/html \
    && a2enmod rewrite

# Копирование конфигурации Apache
COPY apache.conf /etc/apache2/sites-available/000-default.conf

# Установка прав доступа
RUN chmod -R 775 /var/www/html/storage /var/www/html/bootstrap/cache

# Прослушивание HTTP-интерфейса
EXPOSE 80

# Запуск Apache
CMD ["apache2-foreground"]
