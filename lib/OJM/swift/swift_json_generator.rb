# coding: utf-8

module Yousei::OJMGenerator
  module Swift

    class SwiftVariable < Variable
      def self.create_variable(ident, type)
        if type.kind_of? Array
          ArrayType.new ident, self.create_variable(ident, type[0])
        elsif type == 'String'
          StringVariable.new ident, type
        elsif type == 'Int'
          IntegerVariable.new ident, type
        elsif type == 'Double'
          DoubleVariable.new ident, type
        elsif type == 'Bool'
          BoolVariable.new ident, type
        else
          CustomVariable.new ident, type
        end
      end

      def variable_name_in_code
        ident.sv
      end

      def type_expression
        type
      end

      def type_in_nsdictionary
        type_expression
      end

      def optional_cast_from(value_expression)
        "#{value_expression} as? #{type_expression}"
      end

      def default_value_expression
        default_value.inspect
      end

      def to_hash_with(variable_expression, value_expression)
        if @optional
          out = BufferedOutputFormatter.new
          out.line "if let x = #{value_expression} {", '}' do
            out.line to_required_hash_with variable_expression, 'x'
          end
          out.string_array
        else
          to_required_hash_with variable_expression, value_expression
        end
      end

      def to_required_hash_with(variable_expression, value_expression)
        "#{variable_expression} = encode(#{value_expression})"
      end

      def to_value_from(variable_expression, value_expression)
        if @optional
          to_optional_value_from variable_expression, value_expression
        else
          to_required_value_from variable_expression, value_expression
        end
      end

      def to_optional_value_from(variable_expression, value_expression)
        "#{variable_expression} = #{value_expression} as? #{type_expression}"
      end

      def to_required_value_from(variable_expression, value_expression)
        out = BufferedOutputFormatter.new
        out.line "if let x = #{optional_cast_from(value_expression)} {", '} else {' do
          out.line "#{variable_expression} = x"
        end
        out.line nil, '}' do
          out.line 'return nil'
        end
        out.string_array
      end
    end

    class ArrayType < SwiftVariable
      def initialize(ident, type)
        super ident, type
        @inner_type = type
        @generic_type = SwiftVariable::create_variable("#{@symbol}_inarray", @inner_type)
      end

      def type_expression
        "[#{@inner_type.type_expression}]"
      end

      def default_value
        "#{type_expression}()"
      end

      def default_value_expression
        default_value
      end

      def to_required_hash_with(variable_expression, value_expression)
        "#{variable_expression} = #{value_expression}.map {x in encode(x)}"
      end

      def to_optional_value_from(variable_expression, value_expression)
        out = BufferedOutputFormatter.new
        out.line "if let xx = #{value_expression} as? [#{@inner_type.type_in_nsdictionary}] {", '}' do
          if @inner_type.kind_of? CustomVariable
            out.line "#{variable_expression} = #{default_value_expression}"
            out.line 'for x in xx {', '}' do
              out.line "if let obj = #{@inner_type.optional_cast_from('x')} {", '} else {' do
                out.line "#{variable_expression}!.append(obj)"
              end
              out.line nil, '}' do
                out.line 'return nil'
              end
            end
          else
            out.line "#{variable_expression} = xx"
          end
        end
        out.string_array
      end

      def to_required_value_from(variable_expression, value_expression)
        out = BufferedOutputFormatter.new
        out.line "if let xx = #{value_expression} as? [#{@inner_type.type_in_nsdictionary}] {", '} else {' do
          if @inner_type.kind_of? CustomVariable
            out.line 'for x in xx {', '}' do
              out.line "if let obj = #{@inner_type.optional_cast_from('x')} {", '} else {' do
                out.line "#{variable_expression}.append(obj)"
              end
              out.line nil, '}' do
                out.line 'return nil'
              end
            end
          else
            out.line "#{variable_expression} = xx"
          end
        end
        out.line nil, '}' do
          out.line 'return nil'
        end
        out.string_array
      end
    end

    class StringVariable < SwiftVariable
      def default_value
        ''
      end

      def default_value_expression
        '""'
      end

    end

    class IntegerVariable < SwiftVariable
      def default_value
        0
      end
    end

    class DoubleVariable < SwiftVariable
      def default_value
        0
      end
    end

    class BoolVariable < SwiftVariable
      def default_value
        false
      end
    end

    class CustomVariable < SwiftVariable
      def initialize(ident, type)
        super(ident, type)
        @class_name = type_expression
      end

      def default_value_expression
        "#{@class_name}()"
      end

      def type_in_nsdictionary
        'NSDictionary'
      end

      def optional_cast_from(value_expression)
        "#{type_expression}.fromJsonDictionary(#{value_expression})"
      end

      def to_required_hash_with(variable_expression, value_expression)
        "#{variable_expression} = #{value_expression}.toJsonDictionary()"
      end

      def to_optional_value_from(variable_expression, value_expression)
        "#{variable_expression} = " + optional_cast_from("(#{value_expression} as? #{type_in_nsdictionary})")
      end

      def to_required_value_from(variable_expression, value_expression)
        out = BufferedOutputFormatter.new
        out.line 'if let x = ' + optional_cast_from("(#{value_expression} as? #{type_in_nsdictionary})")+ ' {', '} else {' do
          out.line "#{variable_expression} = x"
        end
        out.line nil, '}' do
          out.line 'return nil'
        end
        out.string_array
      end
    end

    ##########################################################

    class SwiftOJMGenerator < GeneratorBase
      def initialize(opts = {})
        Yousei::enable_swift_feature
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
          ret << SwiftVariable::create_variable(ident, type)
        end
        ret
      end

      # For Swift
      def create_class(class_name, attrs)
        dpp attrs
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
