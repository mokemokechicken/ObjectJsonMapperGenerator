# coding: utf-8

module Yousei::OJMGenerator
  module Ruby

    class JsonTypeRuby < JsonType
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

      def default_value_expression
        default_value.inspect
      end

      def to_hash_with(value_expression)
        required_hash_expression = to_required_hash_with value_expression
        if @optional
          "(#{value_expression} == nil ? nil : #{required_hash_expression})"
        else
          required_hash_expression
        end
      end

      def to_required_hash_with(value_expression)
        value_expression
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

    class ArrayType < JsonTypeRuby
      def initialize(key, val)
        super key, val
        @generic_type = JsonTypeRuby::convert_to_type("#{@symbol}_inarray", val[0])
      end

      def default_value
        []
      end

      def to_required_value_from(value_expression)
          "#{value_expression}.to_a.map{|v| #{@generic_type.to_value_from('v')}}"
      end
    end

    class StringType < JsonTypeRuby
      def default_value
        ''
      end

      def default_value_expression
        "''"
      end

      def to_required_value_from(value_expression)
        "#{value_expression}.to_s"
      end
    end

    class IntegerType < JsonTypeRuby
      def default_value
        0
      end

      def to_required_value_from(value_expression)
        "#{value_expression}.to_i"
      end
    end

    class DoubleType < JsonTypeRuby
      def default_value
        0
      end

      def to_required_value_from(value_expression)
        "#{value_expression}.to_f"
      end
    end

    class BoolType < JsonTypeRuby
      def default_value
        false
      end

      def to_required_value_from(value_expression)
        "(#{value_expression} ? true : false)"
      end
    end

    class CustomType < JsonTypeRuby
      def initialize(key, val)
        super(key, val)
        @class_name = val
      end

      def default_value_expression
        "#{@class_name}.new"
      end

      def to_required_value_from(value_expression)
        "#{@class_name}.new.from_json_hash(#{value_expression})"
      end
    end

    ##########################################################

    class RubyOJMGenerator < GeneratorBase
      def initialize(opts = {})
        super(opts)
        @indent_width = 2
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
        outputln File.read(File.expand_path('../ruby_common_scripts.rb', __FILE__)).split /\n/
      end

      def convert_attrs_to_types(attrs)
        ret = []
        attrs.each do |key, val|
          ret << JsonTypeRuby::convert_to_type(key, val)
        end
        ret
      end

      # For Ruby
      def create_class(class_name, attrs)
        dpp attrs
        types =  convert_attrs_to_types attrs
        outputln "class #{class_name} < JsonGenEntityBase", 'end' do
          # accessor
          outputln 'attr_accessor ' + types.map {|t| ":#{t.key}"}. join(', ')
          new_line
          make_constructor types
          new_line
          make_to_json types
          new_line
          make_from_json types
        end
      end

      def make_constructor(types)
        outputln 'def initialize', 'end' do
          types.each do |value_type|
            if value_type.optional
              outputln "@#{value_type.key} = nil"
            else
              outputln "@#{value_type.key} = #{value_type.default_value_expression}"
            end
          end
        end
      end

      def make_to_json(types)
        outputln 'def to_json_hash', 'end' do
          outputln 'hash = {}'
          types.each do |value_type|
            value_expression = "@#{value_type.key}"
            convert_expression = value_type.to_hash_with value_expression
            line = "hash[:#{value_type.key}] = #{convert_expression}"
            if value_type.optional
              line += " unless @#{value_type.key} == nil"
            end
            outputln line
          end
          outputln 'encode(hash)'
        end
      end

      def make_from_json(types)
        outputln 'def from_json_hash(hash)', 'end' do
          types.each do |value_type|
            value_expression = "hash['#{value_type.key}']"
            convert_expression = value_type.to_value_from(value_expression)
            line = "@#{value_type.key} = #{convert_expression}"
            if value_type.optional
              line += " if hash.include? '#{value_type.key}'"
            end
            outputln line
          end
          outputln 'self'
        end
      end
    end
  end
end
