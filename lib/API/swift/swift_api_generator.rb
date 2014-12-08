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
        @yousei_prefix = @api_prefix || 'YouseiAPI'
        @class_prefix = @api_prefix.to_s

        definitions = @api_def

        create_factory definitions

        definitions.each do |api_name, api_attrs|
          create_api_class api_name, api_attrs
        end
      end

      def api_class_name(name)
        "#{@class_prefix}#{name}"
      end

      def yousei_class_name(name)
        "#{@yousei_prefix}#{name}"
      end

      def create_factory(definitions)
        outputln "public class #{api_class_name('Factory')} {" do
          outputln "public let config: #{yousei_class_name 'ConfigProtocol'}"

          outputln "public init(config: #{yousei_class_name 'ConfigProtocol'}) {" do
            outputln 'self.config = config'
          end

          definitions.each do |api_name, _|
            outputln "public func create#{api_name}() -> #{api_class_name api_name} {" do
              outputln "return #{api_class_name api_name}(config: config)"
            end
          end
        end
      end

      def swift_literal(value)
        if value.kind_of? String
          '"' + value + '"'
        else
          value.to_s
        end
      end

      alias_method :sl, :swift_literal

      def method_and_path(api_attrs)
        return ['GET', api_attrs['get']] if api_attrs.include? 'get'
        return ['POST', api_attrs['post']] if api_attrs.include? 'post'
        return ['PUT', api_attrs['put']] if api_attrs.include? 'put'
        return ['PATCH', api_attrs['patch']] if api_attrs.include? 'patch'
        return ['DELETE', api_attrs['delete']] if api_attrs.include? 'delete'
      end

      def create_api_class(api_name, api_attrs)
        class_name = api_class_name api_name
        outputln "public class #{class_name} : #{yousei_class_name :Base} {" do
          create_func_init api_name, api_attrs
          create_class_params api_name, api_attrs
          create_func_call api_name, api_attrs
        end
      end

      def create_func_init(api_name, api_attrs)
        outputln "public init(config: #{yousei_class_name :ConfigProtocol}) {" do
          outputln 'var meta = [String:AnyObject]()'
          if api_attrs['meta'].kind_of? Hash
            api_attrs['meta'].each do |k, v|
              outputln "meta[\"#{k}\"] = #{sl v}"
            end
          end

          method, path = method_and_path api_attrs
          outputln "let apiInfo = #{yousei_class_name :Info}(method: .#{method}, path: #{sl path}, meta: meta)"
          outputln 'super.init(config: config, info: apiInfo)'
        end
      end

      def create_class_params(api_name, api_attrs)

      end

      def create_func_call(api_name, api_attrs)

      end
    end
  end
end
