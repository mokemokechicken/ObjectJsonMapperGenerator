# coding: utf-8

module Yousei::OJMGenerator
  module Swift

    class SwiftType < JsonType
      def self.convert_to_type(key, val)
        if val.kind_of? Array
          ArrayType.new key, self.convert_to_type(key, val[0])
        elsif val == 'String'
          StringType.new key, val
        elsif val == 'Int'
          IntegerType.new key, val
        elsif val == 'Double'
          DoubleType.new key, val
        elsif val == 'Bool'
          BoolType.new key, val
        else
          CustomType.new key, val
        end
      end

      def variable_name_in_code
        key.to_s.camelize false
      end

      def type_expression
        val
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
          out.outputln "if let x = #{value_expression} {", '}' do
            out.outputln to_required_hash_with variable_expression, 'x'
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
        out.outputln "if let x = #{optional_cast_from(value_expression)} {", '} else {' do
          out.outputln "#{variable_expression} = x"
        end
        out.outputln nil, '}' do
          out.outputln 'return nil'
        end
        out.string_array
      end
    end

    class ArrayType < SwiftType
      def initialize(key, val)
        super key, val
        @inner_type = val
        @generic_type = SwiftType::convert_to_type("#{@symbol}_inarray", @inner_type)
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
        out.outputln "if let xx = #{value_expression} as? [#{@inner_type.type_in_nsdictionary}] {", '}' do
          if @inner_type.kind_of? CustomType
            out.outputln "#{variable_expression} = #{default_value_expression}"
            out.outputln 'for x in xx {', '}' do
              out.outputln "if let obj = #{@inner_type.optional_cast_from('x')} {", '} else {' do
                out.outputln "#{variable_expression}!.append(obj)"
              end
              out.outputln nil, '}' do
                out.outputln 'return nil'
              end
            end
          else
            out.outputln "#{variable_expression} = xx"
          end
        end
        out.string_array
      end

      def to_required_value_from(variable_expression, value_expression)
        out = BufferedOutputFormatter.new
        out.outputln "if let xx = #{value_expression} as? [#{@inner_type.type_in_nsdictionary}] {", '} else {' do
          if @inner_type.kind_of? CustomType
            out.outputln 'for x in xx {', '}' do
              out.outputln "if let obj = #{@inner_type.optional_cast_from('x')} {", '} else {' do
                out.outputln "#{variable_expression}.append(obj)"
              end
              out.outputln nil, '}' do
                out.outputln 'return nil'
              end
            end
          else
            out.outputln "#{variable_expression} = xx"
          end
        end
        out.outputln nil, '}' do
          out.outputln 'return nil'
        end
        out.string_array
      end
    end

    class StringType < SwiftType
      def default_value
        ''
      end

      def default_value_expression
        '""'
      end

    end

    class IntegerType < SwiftType
      def default_value
        0
      end
    end

    class DoubleType < SwiftType
      def default_value
        0
      end
    end

    class BoolType < SwiftType
      def default_value
        false
      end
    end

    class CustomType < SwiftType
      def initialize(key, val)
        super(key, val)
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
        out.outputln 'if let x = ' + optional_cast_from("(#{value_expression} as? #{type_in_nsdictionary})")+ ' {', '} else {' do
          out.outputln "#{variable_expression} = x"
        end
        out.outputln nil, '}' do
          out.outputln 'return nil'
        end
        out.string_array
      end
    end

    ##########################################################

    class SwiftOJMGenerator < GeneratorBase
      def initialize(opts = {})
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
        ret = {}
        definitions.each do |klass, v|
          ret[type_map[klass]] = v
        end
        replace_definitions(ret, type_map)
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
        outputln File.read(File.expand_path('../swift_common_scripts.swift', __FILE__)).split /\n/
      end

      def convert_attrs_to_types(attrs)
        ret = []
        attrs.each do |key, val|
          ret << SwiftType::convert_to_type(key, val)
        end
        ret
      end

      # For Swift
      def create_class(class_name, attrs)
        dpp attrs
        types =  convert_attrs_to_types attrs
        outputln "public class #{class_name} : JsonGenEntityBase {", '}' do
          make_member_variables types
          new_line
          make_to_json types
          new_line
          make_from_json class_name, types
        end
      end

      def make_member_variables(types)
        types.each do |t|
          if t.optional
            outputln "var #{t.variable_name_in_code}: #{t.type_expression}?"
          else
            outputln "var #{t.variable_name_in_code}: #{t.type_expression} = #{t.default_value_expression}"
          end
        end
      end

      # @param types Array<JsonTypeSwift>
      def make_to_json(types)
        outputln 'public override func toJsonDictionary() -> NSDictionary {', '}' do
          outputln 'var hash = NSMutableDictionary()'
          types.each do |t|
            outputln "// Encode #{t.variable_name_in_code}"
            value_expression = "self.#{t.variable_name_in_code}"
            variable_expression = "hash[\"#{t.key}\"]"
            outputln t.to_hash_with variable_expression, value_expression
          end
          outputln 'return hash'
        end
      end

      def make_from_json(class_name, types)
        outputln "public override class func fromJsonDictionary(hash: NSDictionary?) -> #{class_name}? {", '}' do
          outputln 'if let h = hash {', '} else {' do
            outputln "var this = #{class_name}()"
            types.each do |t|
              outputln "// Decode #{t.variable_name_in_code}"
              value_expression = "h[\"#{t.key}\"]"
              variable_expression = "this.#{t.variable_name_in_code}"
              outputln t.to_value_from(variable_expression, value_expression)
            end
            outputln 'return this'
          end
          outputln nil, '}' do
            outputln 'return nil'
          end
        end
      end
    end
  end
end
