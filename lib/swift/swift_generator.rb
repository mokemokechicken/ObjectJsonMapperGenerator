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
        out.outputln "if let x = #{value_expression} as? #{type_expression} {", '} else {' do
          out << "#{variable_expression} = x"
        end
        out.outputln nil, '}' do
          out << 'return nil'
        end
        out.string_array
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

      def to_optional_value_from(variable_expression, value_expression)
        out = BufferedOutputFormatter.new
        out.outputln "if let xx = #{value_expression} as? [NSDictionary] {", '}' do
          out << "#{variable_expression} = #{default_value_expression}"
          out.outputln 'for x in xx {', '}' do
            out.outputln "if let obj = #{val[0]}.fromJsonDictionary(x) {", '} else {' do
              out << "#{variable_expression}!.append(obj)"
            end
            out.outputln nil, '}' do
              out << 'return nil'
            end
          end
        end
        out.string_array
      end

      def to_required_value_from(variable_expression, value_expression)
        out = BufferedOutputFormatter.new
        out.outputln "if let xx = #{value_expression} as? [NSDictionary] {", '} else {' do
          out.outputln 'for x in xx {', '}' do
            out.outputln "if let obj = #{val[0]}.fromJsonDictionary(x) {", '} else {' do
              out << "#{variable_expression}.append(obj)"
            end
            out.outputln nil, '}' do
              out << 'return nil'
            end
          end
        end
        out.outputln nil, '}' do
          out << 'return nil'
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

    end

    class IntegerType < JsonTypeSwift
      def default_value
        0
      end
    end

    class DoubleType < JsonTypeSwift
      def default_value
        0
      end
    end

    class BoolType < JsonTypeSwift
      def default_value
        false
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

      def to_optional_value_from(variable_expression, value_expression)
        "#{variable_expression} = #{type_expression}.fromJsonDictionary(#{value_expression} as? NSDictionary)"
      end

      def to_required_value_from(variable_expression, value_expression)
        out = BufferedOutputFormatter.new
        out.outputln "if let x = #{type_expression}.fromJsonDictionary(#{value_expression} as? NSDictionary) {", '} else {' do
          out << "#{variable_expression} = x"
        end
        out.outputln nil, '}' do
          out << 'return nil'
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
          make_from_json class_name, types
        end
      end

      def make_member_variables(types)
        types.each do |t|
          if t.optional
            outputln "var #{t.key}: #{t.type_expression}?"
          else
            outputln "var #{t.key}: #{t.type_expression} = #{t.default_value_expression}"
          end
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

      def make_from_json(class_name, types)
        outputln "override class func fromJsonDictionary(hash: NSDictionary?) -> #{class_name}? {", '}' do
          outputln 'if let h = hash {', '} else {' do
            outputln "var this = #{class_name}()"
            types.each do |value_type|
              value_expression = "h[\"#{value_type.key}\"]"
              variable_expression = "this.#{value_type.key}"
              outputln value_type.to_value_from(variable_expression, value_expression)
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
