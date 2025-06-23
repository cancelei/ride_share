FROM ruby:3.2.1-slim

ENV SOURCE=/app

RUN mkdir -p $SOURCE && \
    mkdir -p /etc/apt/keyrings/

RUN apt-get update -qq && \
    apt-get install -y curl build-essential libpq-dev libxml2-dev libcurl4-openssl-dev libxslt1-dev git ca-certificates lsb-release wget && \
    curl -fsSL https://deb.nodesource.com/setup_lts.x | bash - && \
    wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub > /etc/apt/keyrings/google-chrome.asc && \
    echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/google-chrome.asc] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list && \
    apt-get update -qq && \
    apt-get install -y nodejs google-chrome-stable

ENV RAILS_ENV="development" \
    BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle" \
    CHROME_PATH="/usr/bin/google-chrome-stable" \
    GOOGLE_CHROME_SHIM="/usr/bin/google-chrome-stable" \
    CHROME_PUPPETEER_ARGS="--no-sandbox,--disable-gpu,--disable-dev-shm-usage"

WORKDIR $SOURCE

RUN gem update --system

ADD . $SOURCE

RUN bundle config set path /usr/local/bundle && bundle install

RUN npm install --global yarn && \
    yarn install --frozen-lockfile && \
    bundle exec rails assets:precompile

# ENTRYPOINT ["/usr/src/app/bin/docker-entrypoint"]

EXPOSE $PORT

CMD "rails server"
