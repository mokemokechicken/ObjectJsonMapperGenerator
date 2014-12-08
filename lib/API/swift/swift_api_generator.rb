module Yousei::APIGenerator
  module Swift
    class SwiftGenerator < GeneratorBase
      def create_entity
        generator = Yousei::OJMGenerator::Swift::SwiftOJMGenerator.new
        generator.generate @entity_def
      end

      def create_api
      end
    end
  end
end
