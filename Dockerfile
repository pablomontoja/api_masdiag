FROM ruby:3.1.2-alpine AS builder

RUN apk add --update --no-cache binutils-gold build-base curl file g++ git gcc less libstdc++ libffi-dev libc-dev linux-headers \
												mariadb-dev libxml2-dev libxslt-dev libgcrypt-dev make netcat-openbsd nodejs openssl pkgconfig tzdata yarn sqlite-dev
RUN	rm -rf /var/cache/apk/* && mkdir /app && mkdir /bundle
WORKDIR /app
COPY . /app/
ARG rails_master_key
ARG rails_env
ENV RAILS_MASTER_KEY $rails_master_key
ENV RAILS_ENV $rails_env
ENV RAILS_SERVE_STATIC_FILES true
ENV RAILS_LOG_TO_STDOUT true
ENV GEM_HOME="/bundle"
ENV PATH $GEM_HOME/bin:$GEM_HOME/gems/bin:$PATH
RUN gem install bundler -v 2.3.22 && bundle check || bundle install -j8




FROM builder
# RUN rake assets:clobber assets:precompile

# Add a script to be executed every time the container starts.
COPY entrypoint.sh /usr/bin/
RUN chmod +x /usr/bin/entrypoint.sh
ENTRYPOINT ["entrypoint.sh"]
EXPOSE 3000

# Start the main process.
CMD ["rails", "server", "-b", "0.0.0.0", "-e", $rails_env , "-p", "3000"]