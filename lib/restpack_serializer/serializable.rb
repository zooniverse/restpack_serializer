require 'active_support/concern'
require_relative "options"
require_relative "serializable/attributes"
require_relative "serializable/filterable"
require_relative "serializable/paging"
require_relative "serializable/resource"
require_relative "serializable/single"
require_relative "serializable/side_loading"
require_relative "serializable/side_load_data_builder"
require_relative "serializable/symbolizer"
require_relative "serializable/sortable"

module RestPack
  module Serializer
    extend ActiveSupport::Concern
    mattr_accessor :class_map
    @@class_map ||= {}

    included do
      identifier = self.to_s.underscore.chomp('_serializer')
      @@class_map[identifier] = self
      @@class_map[identifier.split('/').last] = self
    end

    include RestPack::Serializer::Paging
    include RestPack::Serializer::Resource
    include RestPack::Serializer::Single
    include RestPack::Serializer::Attributes
    include RestPack::Serializer::Filterable
    include RestPack::Serializer::SideLoading
    include RestPack::Serializer::Sortable

    class InvalidInclude < Exception; end

    def as_json(model, context = {}, options = nil)
      return if model.nil?
      if model.kind_of?(Array)
        return model.map { |item| as_json(item, context, options) }
      end

      @model, @context = model, context

      data = {}
      if self.class.serializable_attributes.present?
        self.class.serializable_attributes.each do |key, name|
          data[key] = self.send(name) if include_attribute?(name)
        end
      end

      add_custom_attributes(data)
      add_links(model, data, options)

      Symbolizer.recursive_symbolize(data)
    end

    def custom_attributes
      {}
    end

    private

    def add_custom_attributes(data)
      custom = custom_attributes
      data.merge!(custom) if custom
    end

    def add_links(model, data, options)
      self.class.associations.each do |association|
        data[:links] ||= {}
        links_value = case association.macro
        when :belongs_to
          if association.polymorphic?
            linked_id = model.send(association.foreign_key)
                        .try(:to_s)
            linked_type = model.send(association.foreign_type)
                          .try(:to_s)
                          .demodulize
                          .underscore
                          .pluralize
            {
              href: "/#{linked_type}/#{linked_id}",
              id: linked_id,
              type: linked_type
            }
          else
            model.send(association.foreign_key).try(:to_s)
          end
        when :has_one
          model.send(association.name).try(:id).try(:to_s)
        else
          query = model.send association.name
          sorting = options.linked_sorting[association.name.to_s] if options
          query = query.order(sorting) if sorting

          if query.loaded?
            query.collect { |associated| associated.id.to_s }
          else
            query.pluck(:id).map(&:to_s)
          end
        end
        unless links_value.blank?
          data[:links][association.name.to_sym] = links_value
        end
      end
      data
    end

    def include_attribute?(name)
      self.send("include_#{name}?".to_sym)
    end

    module ClassMethods
      attr_accessor :model_class, :href_prefix, :key

      def array_as_json(models, context = {}, options = nil)
        new.as_json(models, context, options)
      end

      def as_json(model, context = {}, options = nil)
        new.as_json(model, context, options)
      end

      def serialize(models, context = {}, options = nil)
        models = [models] unless models.kind_of?(Array)

        {
          self.key() => models.map {|model| self.as_json(model, context, options)}
        }
      end

      def model_class
        @model_class || self.name.chomp('Serializer').constantize
      end

      def href_prefix
        @href_prefix || RestPack::Serializer.config.href_prefix
      end

      def key
        (@key || self.model_class.send(:table_name)).to_sym
      end

      def singular_key
        self.key.to_s.singularize.to_sym
      end

      def plural_key
        self.key
      end
    end
  end
end
