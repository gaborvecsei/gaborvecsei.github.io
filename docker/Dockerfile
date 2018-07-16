FROM ubuntu

RUN apt-get -yq update

RUN apt-get -yq install ruby ruby-dev make build-essential locales
RUN apt-get install -yq patch zlib1g-dev liblzma-dev

RUN echo "GEM_HOME=${HOME}/gems" >> /${HOME}/.bashrc
RUN echo "PATH=${HOME}/gems/bin:${PATH}" >> /${HOME}/.bashrc

RUN locale-gen en_US.UTF-8
ENV LC_ALL C.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8

RUN gem install jekyll bundler

ADD ./code/gaborvecsei.github.io /code/gaborvecsei.github.io

WORKDIR /code/gaborvecsei.github.io

RUN bundle install

RUN chmod +x start.sh