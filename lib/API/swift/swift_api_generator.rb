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
      include Yousei::Swift

      def generate(definitions, opts = nil)
        enable_swift_feature
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
          new_line
          create_api_class api_name, api_attrs
        end
      end

      def create_factory(definitions)
        line "public class #{api_class :Factory} {" do
          line "public let config: #{yousei_class :ConfigProtocol}"

          line "public init(config: #{yousei_class :ConfigProtocol}) {" do
            line 'self.config = config'
          end

          definitions.each do |api_name, _|
            line "public func create#{api_name}() -> #{api_class api_name} {" do
              line "return #{api_class api_name}(config: config)"
            end
          end
        end
      end

      def create_api_class(api_name, api_attrs)
        class_name =  api_class api_name
        line "public class #{class_name} : #{yousei_class :Base} {" do
          create_func_init api_name, api_attrs
          new_line
          create_func_setup api_name, api_attrs
          new_line
          create_func_call api_name, api_attrs
        end
      end

      def create_func_init(api_name, api_attrs)
        line "public init(config: #{yousei_class :ConfigProtocol}) {" do
          line 'var meta = [String:AnyObject]()'
          if api_attrs['meta'].kind_of? Hash
            api_attrs['meta'].each do |k, v|
              line "meta[\"#{k}\"] = #{v.sl}"
            end
          end

          method, path = method_and_path api_attrs
          line "let apiInfo = #{yousei_class :Info}(method: .#{method}, path: #{path.sl}, meta: meta)"
          line 'super.init(config: config, info: apiInfo)'
        end
      end

      def create_func_setup(api_name, api_attrs)
        def make_args_list(api_attrs)
          required_param_list = []
          optional_param_list = []
          if api_attrs['params']
            api_attrs['params'].each do |ident, type|
              var = SwiftVariable::create_variable(ident, type)
              if var.optional
                optional_param_list << var
              else
                required_param_list << var
              end
            end

            params_keys = api_attrs['params'].keys
            path_placeholder_keys(api_attrs).each do |key|
              required_param_list << SwiftVariable::create_variable(key, 'String') unless params_keys.include?(key)
            end
          end
          default_value = ' = nil'
          param_list = required_param_list + optional_param_list
          args_expression = param_list.map {|v|
            "##{v.code_name}: #{v.type_expression_with_optional}#{default_value if v.optional}"
          }.join(', ')
          [args_expression, required_param_list, optional_param_list]
        end

        args_expression, required_param_list, optional_param_list = make_args_list(api_attrs)

        line "public func setup(#{args_expression}) -> #{api_class api_name} {" do
          line 'query = [String:AnyObject]()'
          required_param_list.each do |var|
            line "query[\"#{var.ident}\"] = #{var.code_name}"
          end
          optional_param_list.each do |var|
            line "if let x = #{var.code_name} { query[\"#{var.ident}\"] = x }"
          end

          new_line

          line 'var path = apiRequest.info.path'
          path_placeholder_keys(api_attrs).each do |key|
            line "path = replacePathPlaceholder(path, key: \"#{key}\")"
          end

          line 'apiRequest.request.URL = NSURL(string: path, relativeToURL: config.baseURL)'
          line 'return self'
        end
      end


      def create_func_call(api_name, api_attrs)
        if api_attrs['body'] && required_body_object?(api_attrs)
          create_func_call_with_body(api_name, api_attrs)
        else
          create_func_call_normal(api_name, api_attrs)
        end
      end

      def create_func_call_normal(api_name, api_attrs)
        rvar = SwiftVariable::create_variable 'response', api_attrs['response']
        line "public func call(completionHandler: (#{yousei_class :Response}, #{rvar.type_expression}?) -> Void) {" do
          line 'doRequest() { response in', '}' do
            line "completionHandler(response, #{rvar.from_data_expression 'response.data'} as? #{rvar.type_expression})"
          end
        end
      end

      def create_func_call_with_body(api_name, api_attrs)

      end

      ######################## Helper ################################
      def method_and_path(api_attrs)
        return ['GET', api_attrs['get']] if api_attrs.include? 'get'
        return ['POST', api_attrs['post']] if api_attrs.include? 'post'
        return ['PUT', api_attrs['put']] if api_attrs.include? 'put'
        return ['PATCH', api_attrs['patch']] if api_attrs.include? 'patch'
        return ['DELETE', api_attrs['delete']] if api_attrs.include? 'delete'
      end

      def required_body_object?(api_attrs)
        method, _ = method_and_path api_attrs
        %w(POST PUT PATCH).include? method
      end

      def path_placeholder_keys(api_attrs)
        _, path = method_and_path api_attrs
        path.scan(/\{([^}]+)\}/).map {|x| x[0]}
      end
    end
  end
end
