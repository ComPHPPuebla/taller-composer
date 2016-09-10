FROM php:7.0-cli

COPY ./containers/config/group.sh /group.sh

# Add execution permission
RUN chmod a+x /group.sh

# Create custom user and group to match the ones in the host machine
RUN /group.sh
RUN useradd -ms /bin/bash -g 1000 -u 1000 luis
RUN mkdir -p /composer/.composer
RUN mkdir -p /composer/vendor/bin

RUN mv /home/luis/.bashrc /etc/bashrc
COPY ./containers/config/.bashrc /home/luis/.bashrc

COPY ./containers/config/php.ini /usr/local/etc/php/
COPY ./containers/config/auth.json /composer/.composer/

# Install modules
RUN apt-get update && apt-get install -y \
    && apt-get install -y zlib1g zlib1g-dev git-core \
    && docker-php-ext-install pdo_mysql \
    && docker-php-ext-install mbstring \
    && docker-php-ext-install bcmath \
    && docker-php-ext-install zip

# Install Composer

# Register the COMPOSER_HOME environment variable
ENV COMPOSER_HOME /composer

# Add global binary directory to PATH and make sure to re-export it
ENV PATH /composer/vendor/bin:$PATH

# Allow Composer to be run as root
ENV COMPOSER_ALLOW_SUPERUSER 1

# Setup the Composer installer
RUN curl -o /tmp/composer-setup.php https://getcomposer.org/installer \
  && curl -o /tmp/composer-setup.sig https://composer.github.io/installer.sig \
  && php -r "if (hash('SHA384', file_get_contents('/tmp/composer-setup.php')) !== trim(file_get_contents('/tmp/composer-setup.sig'))) { unlink('/tmp/composer-setup.php'); echo 'Invalid installer' . PHP_EOL; exit(1); }"

RUN php /tmp/composer-setup.php --no-ansi --install-dir=/usr/local/bin --filename=composer && rm -rf /tmp/composer-setup.php

RUN composer --version

# Copy Composer's Github token
COPY ./containers/config/auth.json /composer/

RUN chown -R luis /composer

WORKDIR /usr/src/myapp

USER luis
ENV HOME /home/luis

EXPOSE 8000
