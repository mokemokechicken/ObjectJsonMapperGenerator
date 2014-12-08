module Yousei::APIGenerator
  module Swift
    class SwiftGenerator < GeneratorBase
      def create_entity
        super
        generator = Yousei::OJMGenerator::Swift::SwiftOJMGenerator.new
        generator.generate @entity_def, namespace: @entity_prefix.to_s
      end

      def create_api
        super
        generate @api_def, namespace: @api_prefix.to_s
      end

      def generate(definitions, opts={})
        api_prefix = opts[:namespace].to_s
        definitions.each do |class_name, |
      end
    end
  end
end
