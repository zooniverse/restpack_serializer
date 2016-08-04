module RestPack::Serializer
  class Options
    attr_accessor :page, :page_size, :include, :filters, :serializer,
                  :model_class, :scope, :context, :include_links,
                  :sorting, :linked_sorting, :key

    def initialize(serializer, params = {}, scope = nil, context = {}, key = nil)
      params.symbolize_keys! if params.respond_to?(:symbolize_keys!)

      @page = params[:page] ? params[:page].to_i : 1
      @page_size = params[:page_size] ? params[:page_size].to_i : RestPack::Serializer.config.page_size
      @include = params[:include] ? params[:include].split(',') : []
      @filters = filters_from_params(params, serializer)
      @sorting = sorting_from_params(params, serializer)
      @linked_sorting = linked_sorting_from_params(params)
      @serializer = serializer
      @model_class = serializer.model_class
      @scope = scope || model_class.send(:all)
      @context = context
      @include_links = true
    end

    def scope_with_filters
      scope_filter = {}

      @filters.keys.each do |filter|
        value = query_to_array(@filters[filter])
        scope_filter[filter] = value
      end

      @scope.where(scope_filter)
    end

    def default_page_size?
      @page_size == RestPack::Serializer.config.page_size
    end

    def filters_as_url_params
      @filters.sort.map { |k,v| map_filter_ids(k,v) }.join('&')
    end

    def sorting_as_url_params
      sorting_values = sorting.map { |k, v| v == :asc ? k : "-#{k}" }.join(',')
      "sort=#{sorting_values}"
    end

    def linked_sorting_as_url_params
      linked_sorting.each_pair.collect do |key, val|
        sort_value = val.map{ |k, v| v == :asc ? k : "-#{ k }" }.join ','
        "sort_linked_#{ key }=#{ sort_value }"
      end.join '&'
    end

    private

    def filters_from_params(params, serializer)
      filters = {}
      return filters unless params.is_a?(Hash)
      serializer.filterable_by.each do |filter|
        [filter, "#{filter}s".to_sym].each do |key|
          next unless params.has_key?(key)
          filters[filter] = if [nil, '', 'null'].include?(params[key])
            [nil]
          else
            params[key].to_s.split(',')
          end
        end
      end
      filters
    end

    def sorting_from_params(params, serializer)
      sort_values = params[:sort] && params[:sort].split(',')
      return {} if sort_values.blank? || serializer.serializable_sorting_attributes.blank?
      sorting_parameters = {}

      sort_values.each do |sort_value|
        sort_order = sort_value[0] == '-' ? :desc : :asc
        sort_value = sort_value.gsub(/\A\-/, '').downcase.to_sym
        sorting_parameters[sort_value] = sort_order if serializer.serializable_sorting_attributes.include?(sort_value)
      end
      sorting_parameters
    end

    def linked_sorting_from_params(params)
      return { } unless params.respond_to?(:select)
      { }.tap do |linked_sorting|
        params.select{ |key, val| key =~ /\Asort_linked/ }.each_pair do |type, values|
          begin
            type = type.to_s.match(/\Asort_linked_(.*)$/)[1]
            linked_serializer = RestPack::Serializer.class_map[type.singularize]
            next unless linked_serializer
            sortable = linked_serializer.serializable_sorting_attributes
            ordering = values.split(',').collect do |value|
              direction = value =~ /\A\-/ ? :desc : :asc
              value = value.downcase.gsub(/\A\-/, '')
              next unless sortable.include?(value.to_sym)
              [value.to_sym, direction]
            end.flatten.compact

            linked_sorting[type] = Hash[*ordering] if ordering.any?
          rescue
          end
        end
      end
    end

    def map_filter_ids(key,value)
      case value
      when Hash
        value.map { |k,v| map_filter_ids(k,v) }
      else
         "#{key}=#{value.join(',')}"
      end
    end

    def query_to_array(value)
      case value
        when String
          value.split(',')
        when Hash
          value.each { |k, v| value[k] = query_to_array(v) }
        else
          value
      end
    end
  end
end
