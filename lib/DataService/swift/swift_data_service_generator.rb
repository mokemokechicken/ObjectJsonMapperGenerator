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
      include Yousei::APIGenerator::Swift::Util

      # @param [Hash] definitions
      def generate(definitions, opts=nil)
        enable_swift_feature
        super definitions, opts
        @api_def = create_api(definitions, opts)
        new_line
        create_data_service(prefix: @data_service_prefix)
      end

      def create_api(definitions, opts)
        generator = Yousei::APIGenerator::Swift::SwiftGenerator.new writer: @writer
        generator.generate definitions, opts

        @entity_class_prefix = generator.entity_class_prefix
        @api_class_prefix = generator.api_class_prefix
        @yousei_class_prefix = generator.yousei_class_prefix
        generator.definitions_after_create
      end

      def create_data_service(opts)
        @ds_class_prefix = opts[:prefix]
        output_ds_base_script(@ds_class_prefix, @api_class_prefix, @entity_class_prefix)
        new_line
        create_service_locator @api_def

        create_data_service_class_all @api_def
      end

      def output_ds_base_script(ds_prefix, api_prefix, entity_prefix)
        template = File.read(File.expand_path('../common.swift', __FILE__))
        template.gsub!(/#{TEMPLATE_YOUSEI_DS_PREFIX}/, ds_prefix)
        template.gsub!(/#{TEMPLATE_YOUSEI_API_PREFIX}/, api_prefix)
        template.gsub!(/#{TEMPLATE_YOUSEI_ENTITY_PREFIX}/, entity_prefix)
        line template.split /\n/
      end

      def create_service_locator(api_def)
        line "public class #{ds_class :Locator} {" do
          api_def.each do |api_name, api_attrs|
            rvar = rvar_or_nsnull api_attrs
            line "public var #{api_name.si}: #{ds_class api_name}<#{rvar.type_expression}>!"
          end
          new_line
          line "public convenience init(factory: #{api_class :Factory}) {" do
            line 'self.init()'
            api_def.each do |api_name, api_attrs|
              line "self.#{api_name.si} = #{ds_class api_name}(factory: factory)"
            end
          end
        end
      end

      def create_data_service_class_all(api_def)
        api_def.each do |api_name, api_attrs|
          new_line
          create_data_service_class api_name, api_attrs
        end
      end

      def rvar_or_nsnull(api_attrs)
        rvar, _ = rvar_and_handler_type api_attrs
        rvar || SwiftVariable::create_variable('rvar', 'NSNull')
      end

      def create_data_service_class(api_name, api_attrs)
        rvar = rvar_or_nsnull api_attrs
        line "public class #{ds_class api_name}<ET:#{rvar.type_expression}> : #{ds_class ''}<ET> {" do
          line "public typealias ET = #{rvar.type_expression}"
          new_line
          create_func_init api_attrs
          new_line
          create_func_cache_key_for api_attrs
          new_line
          create_func_data api_attrs
          new_line
          create_func_request api_name, api_attrs
        end
      end

      def create_func_init(api_attrs)
        line "public override init(factory: #{api_class :Factory}) {" do
          line 'super.init(factory: factory)'
        end
      end

      def create_func_cache_key_for(api_attrs)
        args_expression, required_param_list, optional_param_list = make_args_list(api_attrs)

        if args_expression.empty?
          line 'private func cacheKeyFor() -> String { return "_" }'
          return
        end

        line "private func cacheKeyFor(#{args_expression}) -> String {" do
          line 'var params = [String:AnyObject]()'
          required_param_list.each do |var|
            line "params[\"#{var.ident}\"] = #{var.code_name}"
          end
          optional_param_list.each do |var|
            line "if let x = #{var.code_name} { params[\"#{var.ident}\"] = x }"
          end
          line 'return URLUtil.makeQueryString(params)'
        end
      end

      def create_func_data(api_attrs)
        call_args = make_call_args_expression api_attrs
        args_expression, _, _ = make_args_list api_attrs

        line "public func data(#{args_expression}) -> ET? {" do
          line "let key = cacheKeyFor(#{call_args})"
          line 'return findInCache(key)'
        end
      end

      def create_func_request(api_name, api_attrs)
        body_needed = required_body_object?(api_attrs)
        call_args = make_call_args_expression api_attrs
        args_expression, required_param_list, optional_param_list = make_args_list api_attrs

        if body_needed
          body_type = (api_attrs['body'] || 'NSData')
          body_type = "#{api_class api_name}.#{body_type}"  if body_type == 'Body'
          bvar = SwiftVariable::create_variable '_BODY', body_type
          args_expression = make_arg_expression([bvar] + required_param_list, optional_param_list)[1..-1]
        end

        rvar, _ = rvar_and_handler_type api_attrs
        line "public func request(#{args_expression}) {" do
          call_expression = body_needed ?  "call(#{bvar.code_name})" : 'call'
          callback = rvar ? 'res, object' : 'res'
          line "factory.create#{api_name}().setup(#{call_args}).#{call_expression} { #{callback} in", '}' do

          end
        end

      end


    end
  end
end
