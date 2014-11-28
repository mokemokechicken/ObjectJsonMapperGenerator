# coding: utf-8

module OJMGenerator
  module Swift

    class JsonTypeSwift < JsonType
      def self.convert_to_type(key, val)
        if val.kind_of? Array
          ArrayType.new key, val
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

      def type_expression
        val
      end

      def default_value_expression
        default_value.inspect
      end

      def to_hash_with(value_expression)
        to_required_hash_with value_expression
      end

      def to_required_hash_with(value_expression)
        "encode(#{value_expression})"
      end

      def to_value_from(value_expression)
        required_value_convert_expression = to_required_value_from value_expression
        if @optional
          "(#{value_expression} == nil ? nil : #{required_value_convert_expression})"
        else
          required_value_convert_expression
        end
      end
    end

    class ArrayType < JsonTypeSwift
      def initialize(key, val)
        super key, val
        @generic_type = JsonTypeSwift::convert_to_type("#{@symbol}_inarray", val[0])
      end

      def type_expression
        "[#{val[0]}]"
      end

      def default_value
        "#{type_expression}()"
      end

      def default_value_expression
        default_value
      end

      def to_required_hash_with(value_expression)
        "#{value_expression}.map { x in encode(x) }"
      end

      def to_required_value_from(value_expression)
        out = BufferedOutputFormatter.new
        out.outputln "if let xx = #{value_expression} as? NSArray {", '}' do

        end
        out.string_array
      end
    end

    class StringType < JsonTypeSwift
      def default_value
        ''
      end

      def default_value_expression
        '""'
      end

      def to_required_value_from(value_expression)
        "#{value_expression} as String"
      end
    end

    class IntegerType < JsonTypeSwift
      def default_value
        0
      end

      def to_required_value_from(value_expression)
        "#{value_expression} as Int"
      end
    end

    class DoubleType < JsonTypeSwift
      def default_value
        0
      end

      def to_required_value_from(value_expression)
        "#{value_expression} as Double"
      end
    end

    class BoolType < JsonTypeSwift
      def default_value
        false
      end

      def to_required_value_from(value_expression)
        "#{value_expression} as Bool"
      end
    end

    class CustomType < JsonTypeSwift
      def initialize(key, val)
        super(key, val)
        @class_name = type_expression
      end

      def default_value_expression
        "#{@class_name}()"
      end

      def to_required_value_from(value_expression)
        "#{@class_name}(#{value_expression})"
      end
    end

    ##########################################################

    class SwiftOJMGenerator < GeneratorBase
      def initialize(opts = {})
        super(opts)
        @indent_width = 4
      end


      def with_namespace(namespace)
        if namespace
          outputln "module #{namespace}", 'end' do
            super namespace
          end
        else
          super namespace
        end
      end

      def output_common_functions
        outputln File.read(File.expand_path('../swift_common_scripts.swift', __FILE__)).split /\n/
      end

      def convert_attrs_to_types(attrs)
        ret = []
        attrs.each do |key, val|
          ret << JsonTypeSwift::convert_to_type(key, val)
        end
        ret
      end

      # For Swift
      def create_class(class_name, attrs)
        dpp attrs
        types =  convert_attrs_to_types attrs
        outputln "class #{class_name} : JsonGenEntityBase {", '}' do
          make_member_variables types
          new_line
          make_to_json types
          new_line
          make_from_json types
        end
      end

      def make_member_variables(types)
        types.each do |t|
          outputln "var #{t.key}: #{t.type_expression} = #{t.default_value_expression}"
        end
      end

      # @param types Array<JsonTypeSwift>
      def make_to_json(types)
        outputln 'override func toJsonDictionary() -> NSDictionary {', '}' do
          outputln 'var hash = NSMutableDictionary()'
          types.each do |t|
            value_expression = "self.#{t.key}"
            convert_expression = t.to_hash_with value_expression
            line = "hash[\"#{t.key}\"] = #{convert_expression}"
            outputln line
          end
          outputln 'return hash'
        end
      end

      def make_from_json(types)
        outputln 'def from_json_hash(hash)', 'end' do
          types.each do |value_type|
            value_expression = "hash['#{value_type.key}']"
            convert_expression = value_type.to_value_from(value_expression)
            if convert_expression.kind_of? Array
              outputln convert_expression
            else
              outputln "@#{value_type.key} = #{convert_expression}"
            end
          end
        end
      end
    end
  end
end
