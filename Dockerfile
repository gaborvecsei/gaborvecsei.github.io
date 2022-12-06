FROM jekyll/builder:4.2.2

COPY . /src

WORKDIR /src

RUN bundle install

