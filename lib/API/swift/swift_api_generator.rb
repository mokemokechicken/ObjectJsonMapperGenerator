module Yousei::APIGenerator
  module Swift
    module Util
      def api_class(s)
        "#{@api_class_prefix}#{s}"
      end

      def yousei_class(s)
        "#{@yousei_class_prefix}#{s}"
      end
    end


    class SwiftGenerator < GeneratorBase
      include Util

      def generate(definitions, opts = nil)
        Yousei::enable_swift_feature
        super definitions, opts
      end

      def create_entity(opts)
        super
        generator = Yousei::OJMGenerator::Swift::SwiftOJMGenerator.new
        generator.generate opts[:def], namespace: opts[:prefix].to_s
      end

      def create_api(opts)
        super(opts)
        @api_class_prefix = opts[:prefix].to_s
        @yousei_class_prefix = opts[:prefix] || 'YouseiAPI'

        definitions = opts[:def]

        create_factory definitions
        definitions.each do |api_name, api_attrs|
          create_api_class api_name, api_attrs
        end
      end

      def create_factory(definitions)
        outputln "public class #{api_class :Factory} {" do
          outputln "public let config: #{yousei_class :ConfigProtocol}"

          outputln "public init(config: #{yousei_class :ConfigProtocol}) {" do
            outputln 'self.config = config'
          end

          definitions.each do |api_name, _|
            outputln "public func create#{api_name}() -> #{api_class api_name} {" do
              outputln "return #{api_class api_name}(config: config)"
            end
          end
        end
      end


      def method_and_path(api_attrs)
        return ['GET', api_attrs['get']] if api_attrs.include? 'get'
        return ['POST', api_attrs['post']] if api_attrs.include? 'post'
        return ['PUT', api_attrs['put']] if api_attrs.include? 'put'
        return ['PATCH', api_attrs['patch']] if api_attrs.include? 'patch'
        return ['DELETE', api_attrs['delete']] if api_attrs.include? 'delete'
      end

      def create_api_class(api_name, api_attrs)
        class_name =  api_class api_name
        outputln "public class #{class_name} : #{yousei_class :Base} {" do
          create_func_init api_name, api_attrs
          create_class_params api_name, api_attrs
          create_func_call api_name, api_attrs
        end
      end

      def create_func_init(api_name, api_attrs)
        outputln "public init(config: #{yousei_class :ConfigProtocol}) {" do
          outputln 'var meta = [String:AnyObject]()'
          if api_attrs['meta'].kind_of? Hash
            api_attrs['meta'].each do |k, v|
              outputln "meta[\"#{k}\"] = #{v.sl}"
            end
          end

          method, path = method_and_path api_attrs
          outputln "let apiInfo = #{yousei_class :Info}(method: .#{method}, path: #{path.sl}, meta: meta)"
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
