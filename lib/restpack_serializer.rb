require 'kaminari'

require 'restpack_serializer/version'
require 'restpack_serializer/configuration'
require 'restpack_serializer/serializable'
require 'restpack_serializer/factory'
require 'restpack_serializer/result'

Kaminari::Hooks.init

module RestPack
  module Serializer
    mattr_accessor :config
    @@config = Configuration.new

    def self.setup
      yield @@config
    end

    def self.select_association_serializer(association)
      begin
        RestPack::Serializer::Factory.create(association.name.to_s.classify)
      rescue RestPack::Serializer::UnknownSerializer
        RestPack::Serializer::Factory.create(association.class_name)
      end
    end
  end
end
