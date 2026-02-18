FROM ruby:2.7-bullseye

RUN apt-get update && apt-get install -y --no-install-recommends libsqlite3-dev && rm -rf /var/lib/apt/lists/*

WORKDIR /restpack

ADD ./Gemfile /restpack/
ADD ./restpack_serializer.gemspec /restpack/
ADD ./lib/restpack_serializer/version.rb /restpack/lib/restpack_serializer/
ADD .git/ /restpack/

RUN bundle config --global jobs `cat /proc/cpuinfo | grep processor | wc -l | xargs -I % expr % - 1` && \
    bundle install

CMD ["bundle", "exec", "rake", "test"]

