# coding: utf-8

module Yousei::OJMGenerator
  module Swift
    class SwiftOJMGenerator < GeneratorBase
      def initialize(opts = {})
        Yousei::Swift::enable_swift_feature
        super(opts)
        @indent_width = 4
      end


      def with_namespace(namespace)
        # Namespace isn't supported
        @class_prefix = namespace
        super namespace
      end

      def customize_definitions(definitions)
        return definitions unless @class_prefix
        type_map = definitions.keys.reduce({}) {|t,x| t[x] = "#{@class_prefix}#{x}"; t }
        definitions = replace_custom_type_name definitions, type_map
        replace_definitions(definitions, type_map)
      end

      def replace_custom_type_name(definitions, type_map)
        ret = {}
        definitions.each do |klass, v|
          ret[type_map[klass]] = v
        end
        ret
      end

      def replace_definitions(values, type_map)
        return (type_map[values] || values) unless values.kind_of?(Array) || values.kind_of?(Hash)
        if values.kind_of? Array
          values.map { |x| replace_definitions(x, type_map) }
        elsif values.kind_of? Hash
          ret = {}
          values.each do |kk, vv|
            ret[kk] = replace_definitions(vv, type_map)
          end
          ret
        end
      end

      def output_common_functions
        line File.read(File.expand_path('../swift_common_scripts.swift', __FILE__)).split /\n/
      end

      def convert_attrs_to_variables(attrs)
        ret = []
        attrs.each do |ident, type|
          ret << Yousei::Swift::SwiftVariable::create_variable(ident, type)
        end
        ret
      end

      # For Swift
      def create_class(class_name, attrs)
        variables =  convert_attrs_to_variables attrs
        line "public class #{class_name} : JsonGenEntityBase {", '}' do
          make_member_variables variables
          new_line
          make_to_json variables
          new_line
          make_from_json class_name, variables
        end
      end

      def make_member_variables(variables)
        variables.each do |var|
          if var.optional
            line "var #{var.variable_name_in_code}: #{var.type_expression}?"
          else
            line "var #{var.variable_name_in_code}: #{var.type_expression} = #{var.default_value_expression}"
          end
        end
      end

      # @param variables Array<JsonTypeSwift>
      def make_to_json(variables)
        line 'public override func toJsonDictionary() -> NSDictionary {', '}' do
          line 'var hash = NSMutableDictionary()'
          variables.each do |var|
            line "// Encode #{var.variable_name_in_code}"
            value_expression = "self.#{var.variable_name_in_code}"
            variable_expression = "hash[\"#{var.ident}\"]"
            line var.to_hash_with variable_expression, value_expression
          end
          line 'return hash'
        end
      end

      def make_from_json(class_name, variables)
        line "public override class func fromJsonDictionary(hash: NSDictionary?) -> #{class_name}? {" do
          line 'if let h = hash {', '} else {' do
            line "var this = #{class_name}()"
            variables.each do |var|
              line "// Decode #{var.variable_name_in_code}"
              value_expression = "h[\"#{var.ident}\"]"
              variable_expression = "this.#{var.variable_name_in_code}"
              line var.to_value_from(variable_expression, value_expression)
            end
            line 'return this'
          end
          line nil, '}' do
            line 'return nil'
          end
        end
      end
    end
  end
end
