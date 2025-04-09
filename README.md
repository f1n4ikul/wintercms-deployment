# Развертывание проекта Winter CMS с использованием Docker

В документации приведены все необходимые шаги для успешного запуска проекта.

---

## Этапы развертывания

### 1. Клонирование репозитория
Необходимо клонировать репозиторий Winter CMS с использованием команды:

```bash
git clone https://github.com/wintercms/winter.git
cd winter
```


---

### 2. Создание файла `.env`
Необходимо создать файл `.env` на основе примера `.env.example`:

```bash
cp .env.example .env
```

После создания файла необходимо открыть его в текстовом редакторе и проверить параметры базы данных. Пример конфигурации:

```env
DB_CONNECTION=mysql
DB_HOST=db
DB_PORT=3306
DB_DATABASE=wintercms
DB_USERNAME=root
DB_PASSWORD=secret
```

---

### 3. Проверка файла `docker-compose.yml`
Необходимо убедиться, что файл `docker-compose.yml` содержит правильные настройки. Пример содержимого:

```yaml
version: '3.8'

services:
  app:
    build:
      context: .
      dockerfile: Dockerfile
    container_name: wintercms-app
    ports:
      - "8080:80"
    volumes:
      - .:/var/www/html
    environment:
      - DB_HOST=db
      - DB_DATABASE=wintercms
      - DB_USERNAME=root
      - DB_PASSWORD=secret
    depends_on:
      - db

  db:
    image: mysql:8.0
    container_name: wintercms-db
    environment:
      MYSQL_ROOT_PASSWORD: secret
      MYSQL_DATABASE: wintercms
    volumes:
      - db_data:/var/lib/mysql

volumes:
  db_data:
```

---

### 4. Создание файла `Dockerfile`
Необходимо создать файл `Dockerfile` в корне проекта со следующим содержимым:

```dockerfile
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
```

---

### 5. Создание файла `apache.conf`
Необходимо создать файл `apache.conf` в корне проекта со следующим содержимым:

```apache
<VirtualHost *:80>
    DocumentRoot /var/www/html

    <Directory /var/www/html>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog ${APACHE_LOG_DIR}/error.log
    CustomLog ${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
```
---

### 6. Создание файла `.gitlab-ci.yml`
Необходимо создать файл `.gitlab-ci.yml` в корне проекта со следующим содержимым:

```yaml
stages:
  - build
  - test
  - deploy

variables:
  DOCKER_DRIVER: overlay2
  IMAGE_TAG: $CI_REGISTRY_IMAGE:$CI_COMMIT_REF_SLUG

build:
  stage: build
  script:
    - docker build -t $IMAGE_TAG .
    - docker login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $CI_REGISTRY
    - docker push $IMAGE_TAG

test:
  stage: test
  script:
    - docker run --rm $IMAGE_TAG php artisan config:cache
    - docker run --rm $IMAGE_TAG php artisan route:list

deploy:
  stage: deploy
  script:
    - echo "Deploying to production..."
    # Здесь можно добавить команды для деплоя, например, через SSH или Kubernetes
  only:
    - main
```

---

### 7. Сборка и запуск Docker-контейнеров
Необходимо выполнить сборку Docker-образов с помощью команды:

```bash
docker-compose up --build
```

---

### 8. Установка зависимостей Composer
После запуска контейнеров необходимо установить зависимости PHP внутри контейнера:

```bash
docker exec -it wintercms-app composer install
```

---

### 9. Генерация ключа приложения
Необходимо сгенерировать ключ приложения Laravel/Winter CMS:

```bash
docker exec -it wintercms-app php artisan key:generate
```

---

### 10. Выполнение миграций базы данных
Необходимо выполнить миграции для базы данных MySQL:

```bash
docker exec -it wintercms-app php artisan migrate
```

---

### 11. Очистка кэша
Необходимо очистить кэш Laravel, чтобы применить изменения:

```bash
docker exec -it wintercms-app php artisan config:clear
docker exec -it wintercms-app php artisan cache:clear
docker exec -it wintercms-app php artisan view:clear
```

---

### 12. Проверка работы проекта
Необходимо открыть браузер и перейти по адресу:

```
http://localhost:8080
```

Если все настроено правильно, отобразится страница Winter CMS.

---

## Дополнительные команды

### Остановка контейнеров
Для остановки контейнеров необходимо выполнить:

```bash
docker-compose down
```

### Просмотр логов контейнеров
Для просмотра логов контейнеров необходимо использовать:

```bash
docker logs wintercms-app
docker logs wintercms-db
```

### Перезапуск контейнеров
Для перезапуска контейнеров необходимо выполнить:

```bash
docker-compose restart
```

---

## Решение распространенных проблем

### 1. Ошибка "Permission denied"
Если возникает ошибка с правами доступа к файлам (например, `storage/logs/system.log`), необходимо выполнить следующие команды:

```bash
docker exec -it wintercms-app chmod -R 775 storage/cms/cache storage/framework/cache bootstrap/cache storage
docker exec -it wintercms-app chown -R www-data:www-data storage/cms/cache storage/framework/cache bootstrap/cache storage
```

### 2. Проблемы с базой данных
Если база данных не создается автоматически:
1. Подключиться к контейнеру MySQL:
   ```bash
   docker exec -it wintercms-db mysql -u root -p
   ```
2. Ввести пароль (`secret`).
3. Создать базу данных вручную:
   ```sql
   CREATE DATABASE wintercms;
   ```
