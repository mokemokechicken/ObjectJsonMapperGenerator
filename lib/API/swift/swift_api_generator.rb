module Yousei::APIGenerator
  module Swift
    module Util
      include Yousei::Swift

      def entity_class(s)
        "#{@entity_class_prefix}#{s}"
      end

      def api_class(s)
        "#{@api_class_prefix}#{s}"
      end

      def yousei_class(s)
        "#{@yousei_class_prefix}#{s}"
      end

      ######################## Helper ################################
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
        end

        params_keys = (api_attrs['params'] || {}).keys
        path_placeholder_keys(api_attrs).each do |key|
          required_param_list << SwiftVariable::create_variable(key, 'String') unless params_keys.include?(key)
        end

        args_expression = make_arg_expression required_param_list, optional_param_list
        [args_expression, required_param_list, optional_param_list]
      end

      def make_arg_expression(required_param_list, optional_param_list)
        default_value = ' = nil'
        param_list = required_param_list + optional_param_list
        args_expression_list = []
        param_list.each_with_index  do |v, i|
          if i == 0 && !v.optional
            var_name = "##{v.code_name}"
          else
            var_name = v.code_name
          end
          args_expression_list << "#{var_name}: #{v.type_expression_with_optional}#{default_value if v.optional}"
        end
        args_expression_list.join(', ')
      end

      def make_call_args_expression(api_attrs)
        _, required_param_list, optional_param_list = make_args_list(api_attrs)
        (required_param_list + optional_param_list).map {|v| "#{v.code_name}: #{v.code_name}"}.join(', ')
      end

      def api_response_info(api_attrs)
        response_var = api_attrs['response'] ? SwiftVariable::create_variable('response', api_attrs['response']) : nil
        error_var = api_attrs['error'] ? SwiftVariable::create_variable('error', api_attrs['error']) : nil
        body_var = api_attrs['body'] ? SwiftVariable::create_variable('body', api_attrs['body']) : nil

        handler_type = if response_var
                         "(#{yousei_class :Response}, #{response_var.type_expression}?) -> Void"
                       else
                         "(#{yousei_class :Response}) -> Void"
                       end
        [response_var, handler_type]
        return {response_var: response_var, error_var: error_var, body_var: body_var, handler_type: handler_type}
      end

      def required_body_object?(api_attrs)
        method, _ = method_and_path api_attrs
        %w(POST PUT PATCH).include? method
      end

      def path_placeholder_keys(api_attrs)
        _, path = method_and_path api_attrs
        path.scan(/\{([^}]+)\}/).map {|x| x[0]}
      end

      def method_and_path(api_attrs)
        return ['GET', api_attrs['get']] if api_attrs.include? 'get'
        return ['POST', api_attrs['post']] if api_attrs.include? 'post'
        return ['PUT', api_attrs['put']] if api_attrs.include? 'put'
        return ['PATCH', api_attrs['patch']] if api_attrs.include? 'patch'
        return ['DELETE', api_attrs['delete']] if api_attrs.include? 'delete'
      end
    end

    class SwiftGenerator < GeneratorBase
      attr_accessor :entity_class_prefix, :api_class_prefix, :yousei_class_prefix
      attr_accessor :definitions_after_create
      TEMPLATE_YOUSEI_API_PREFIX = 'YOUSEI_API_GENERATOR_PREFIX_'
      TEMPLATE_YOUSEI_ENTITY_PREFIX = 'YOUSEI_ENTITY_PREFIX_'

      include Util

      def initialize(opts={})
        super opts
        @ext = 'swift'
        @writer.register_hook_open_new_file do |info|
          line 'import Foundation'
          new_line
        end
      end

      def generate(definitions, opts = nil)
        enable_swift_feature
        super definitions, opts
      end

      def pre_process_definitions
        @api_def.each do |_, api_attrs|
          set_api_error_entity(api_attrs, @definitions['api_error_entity'])
        end
      end

      def set_api_error_entity(api_attrs, entity_name)
        return unless entity_name
        api_attrs['error'] = entity_name unless api_attrs['error']
      end

      def create_entity(opts)
        super
        generator = Yousei::OJMGenerator::Swift::SwiftOJMGenerator.new writer: @writer
        generator.generate opts[:def], namespace: opts[:prefix].to_s

        @entity_class_prefix = opts[:prefix].to_s
        @api_def = generator.replace_definitions(@api_def)
      end

      def create_api(opts)
        super(opts)
        @api_class_prefix = opts[:prefix].to_s
        @yousei_class_prefix = opts[:prefix] || 'YouseiAPI'

        api_def = opts[:def]

        @writer.change_filename "#{api_class :Common}.#{@ext}"
        output_api_base_script(@api_class_prefix, @entity_class_prefix)

        @writer.change_filename "#{api_class :Factory}.#{@ext}"
        create_factory api_def
        @definitions_after_create = {}
        api_def.each do |api_name, api_attrs|
          @writer.change_filename "#{api_class api_name}.#{@ext}"
          @definitions_after_create[api_name] = create_api_class api_name, api_attrs
        end
      end

      def output_api_base_script(api_prefix, entity_prefix)
        template = File.read(File.expand_path('../common.swift', __FILE__))
        template.gsub!(/#{TEMPLATE_YOUSEI_API_PREFIX}/, api_prefix)
        template.gsub!(/#{TEMPLATE_YOUSEI_ENTITY_PREFIX}/, entity_prefix)
        line template.split /\n/
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
          %w(body response).each do |name|
            if api_attrs[name].kind_of?(Hash) && required_body_object?(api_attrs)
              replace_and_create_entity(name, api_attrs)
              new_line
            end
          end
          create_type_aliases api_attrs
          new_line
          create_func_init api_name, api_attrs
          new_line
          create_func_setup api_name, api_attrs
          new_line
          create_func_call api_name, api_attrs
          new_line
          create_error_info api_attrs
        end
        api_attrs
      end

      def replace_and_create_entity(name, api_attrs)
        hash = api_attrs[name]
        api_attrs[name] = type_name = name.camelize
        entity_generator = Yousei::OJMGenerator::Swift::SwiftOJMGenerator.new indent: @indent, writer: @writer
        entity_generator.entity_class_prefix = @entity_class_prefix
        entity_generator.create_class type_name, hash
      end

      def create_type_aliases(api_attrs)
        info = api_response_info api_attrs
        line "public typealias EntityType = #{info[:response_var].type_expression}"  if info[:response_var]
        line "public typealias ErrorType = #{info[:error_var].type_expression}"  if info[:error_var]
        line "public typealias BodyType = #{info[:body_var].type_expression}"  if info[:body_var]
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
        if required_body_object?(api_attrs)
          create_func_call_with_body(api_name, api_attrs)
        else
          create_func_call_normal(api_name, api_attrs)
        end
      end

      def create_func_call_normal(api_name, api_attrs)
        info = api_response_info api_attrs
        line "public func call(completionHandler: #{info[:handler_type]}) {" do
          create_do_request info[:response_var], false
        end
      end

      def create_func_call_with_body(api_name, api_attrs)
        info = api_response_info api_attrs
        bvar = SwiftVariable::create_variable 'body', (api_attrs['body'] || 'NSData')
        line "public func call(object: #{bvar.type_expression}, completionHandler: #{info[:handler_type]}) {" do
          create_do_request info[:response_var], true
        end
      end

      def create_do_request(rvar, with_object = false)
        line "doRequest(#{'object' if with_object}) { response in", '}' do
          if rvar
            response = "#{rvar.from_data_expression 'response.data'} as? #{rvar.type_expression}"
            line "completionHandler(response, #{response})"
          else
            line 'completionHandler(response)'
          end
        end
      end

      def create_error_info(api_attrs)
        info = api_response_info api_attrs
        if info[:error_var]
          line "public class func errorInfo(response: #{yousei_class :Response}) -> #{info[:error_var].type_expression}? {" do
            line 'return ErrorType.fromData(response.data) as ErrorType?'
          end
        end
      end
    end
  end
end
