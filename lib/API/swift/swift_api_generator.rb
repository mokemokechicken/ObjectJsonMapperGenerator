module Yousei::APIGenerator
  module Swift
    class SwiftGenerator < GeneratorBase
      def create_entity
        generator = Yousei::OJMGenerator::Swift::SwiftOJMGenerator.new
        generator.generate @entity_def, namespace: @entity_prefix.to_s
      end

      def create_api
      end
    end
  end
end
