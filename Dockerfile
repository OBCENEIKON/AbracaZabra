FROM ubuntu

RUN apt-get update -qq && apt-get -q -y install libsqlite3-dev ruby ruby-dev build-essential

ENV RAILS_ENV="production" \
    SECRET_KEY_BASE="$(openssl rand -base64 32)"

RUN echo "gem: --no-ri --no-rdoc" > ~/.gemrc \
    && gem install bundler
RUN mkdir -p /app
WORKDIR /app
COPY Gemfile* /app/
RUN bundle install --without development test --jobs 4
COPY . /app/
RUN bundle exec rake assets:precompile

EXPOSE 3000