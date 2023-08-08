# [Choice] PHP version (use -bullseye variants on local arm64/Apple Silicon): 8, 8.1, 8.0, 7, 7.4, 7.3, 8-bullseye, 8.1-bullseye, 8.0-bullseye, 7-bullseye, 7.4-bullseye, 7.3-bullseye, 8-buster, 8.1-buster, 8.0-buster, 7-buster, 7.4-buster
ARG VARIANT="8.0"
FROM mcr.microsoft.com/vscode/devcontainers/php:0-${VARIANT} 
# Install MariaDB client
# Fix for Missing Key in https://dl.yarnpkg.com/debian stable InRelease | https://github.com/yarnpkg/yarn/issues/7866
# RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
# RUN echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
# RUN sudo apt update
# RUN sudo apt install yarn
RUN sudo a2enmod rewrite

RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && apt-get install -y mariadb-client \ 
    && apt-get clean -y && rm -rf /var/lib/apt/lists/*

# Install php-mysql driver
RUN docker-php-ext-install mysqli pdo pdo_mysql


# [Choice] Node.js version: none, lts/*, 16, 14, 12, 10
ARG NODE_VERSION="none"
RUN if [ "${NODE_VERSION}" != "none" ]; then su vscode -c "umask 0002 && . /usr/local/share/nvm/nvm.sh && nvm install ${NODE_VERSION} 2>&1"; fi

# [Optional] Uncomment this section to install additional OS packages.
RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && apt-get -y install --no-install-recommends cron libzip-dev zip libpng-dev libicu-dev libxml2-dev libyaml-dev libxslt-dev libwebp-dev libfreetype6-dev libjpeg62-turbo-dev

# [Optional] Uncomment this line to install global node packages.
# RUN su vscode -c "source /usr/local/share/nvm/nvm.sh && npm install -g <your-package-here>" 2>&1

# Install zip
RUN docker-php-ext-install zip

# Install ImageMagick
RUN apt-get install -y libmagickwand-dev --no-install-recommends && rm -rf /var/lib/apt/lists/*
RUN printf "\n" | pecl install imagick
RUN docker-php-ext-enable imagick

# Install OpenJDK
RUN apt update && apt install -y default-jdk 
# OPT && apt install -y default-jre

# Install gd
RUN docker-php-ext-configure gd --with-jpeg --with-webp --with-freetype
RUN docker-php-ext-install gd

# Install soap
RUN docker-php-ext-install soap

# Install xml
RUN docker-php-ext-install xml

# Set PHP variables for ILIAS
RUN echo 'max_execution_time = 300' >> /usr/local/etc/php/conf.d/docker-php-maxexectime.ini;
RUN echo 'upload_max_filesize = 2048M' >> /usr/local/etc/php/conf.d/docker-php-uploadmaxfilesize.ini;
RUN echo 'post_max_size = 2048M' >> /usr/local/etc/php/conf.d/docker-php-postmaxsize.ini;
RUN echo 'max_input_vars = 5000' >> /usr/local/etc/php/conf.d/docker-php-maxinputvars.ini;
RUN echo 'date.timezone = Europe/Amsterdam' >> /usr/local/etc/php/conf.d/docker-php-datetimezone.ini;
RUN echo 'memory_limit = 512M' >> /usr/local/etc/php/conf.d/docker-php-memlimit.ini;