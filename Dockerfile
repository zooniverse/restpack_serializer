FROM ruby:2.5

RUN apt-get update && apt-get install -y nano vim

WORKDIR /restpack

ADD ./Gemfile /restpack/
ADD ./restpack_serializer.gemspec /restpack/
ADD ./lib/restpack_serializer/version.rb /restpack/lib/restpack_serializer/
ADD .git/ /restpack/

RUN bundle config --global jobs `cat /proc/cpuinfo | grep processor | wc -l | xargs -I % expr % - 1` && \
    bundle install

CMD ["bundle", "exec", "rake", "test"]

