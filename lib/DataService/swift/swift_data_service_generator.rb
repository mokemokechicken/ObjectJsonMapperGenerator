module Yousei::DataServiceGenerator
  module Swift

    module Util
      def ds_class(s)
        "#{@ds_class_prefix}#{s}"
      end

      def entity_class(s)
        "#{@entity_class_prefix}#{s}"
      end

      def api_class(s)
        "#{@api_class_prefix}#{s}"
      end

      def yousei_class(s)
        "#{@yousei_class_prefix}#{s}"
      end
    end


    class SwiftGenerator < GeneratorBase
      attr_accessor :entity_class_prefix, :api_class_prefix, :yousei_class_prefix, :data_service_prefix
      TEMPLATE_YOUSEI_DS_PREFIX = 'TEMPLATE_YOUSEI_DS_PREFIX_'
      TEMPLATE_YOUSEI_API_PREFIX = 'YOUSEI_API_GENERATOR_PREFIX_'
      TEMPLATE_YOUSEI_ENTITY_PREFIX = 'YOUSEI_ENTITY_PREFIX_'

      include Util
      include Yousei::Swift

      # @param [Hash] definitions
      def generate(definitions, opts=nil)
        enable_swift_feature
        super definitions, opts
        create_api(definitions, opts)
        new_line
        create_data_service(definitions, prefix: @data_service_prefix)
      end

      def create_api(definitions, opts)
        generator = Yousei::APIGenerator::Swift::SwiftGenerator.new writer: @writer
        generator.generate definitions, opts

        @entity_class_prefix = generator.entity_class_prefix
        @api_class_prefix = generator.api_class_prefix
        @yousei_class_prefix = generator.yousei_class_prefix
      end

      def create_data_service(definitions, opts)
        @ds_class_prefix = opts[:prefix]
        output_ds_base_script(@ds_class_prefix, @api_class_prefix, @entity_class_prefix)
        new_line
        #create_service_locator()
      end

      def output_ds_base_script(ds_prefix, api_prefix, entity_prefix)
        template = File.read(File.expand_path('../common.swift', __FILE__))
        template.gsub!(/#{TEMPLATE_YOUSEI_DS_PREFIX}/, ds_prefix)
        template.gsub!(/#{TEMPLATE_YOUSEI_API_PREFIX}/, api_prefix)
        template.gsub!(/#{TEMPLATE_YOUSEI_ENTITY_PREFIX}/, entity_prefix)
        line template.split /\n/
      end
    end
  end
end
