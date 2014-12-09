# coding: utf-8

module Yousei::OJMGenerator
  module Ruby
    include Yousei
    class RubyVariable < Variable
      def self.convert_to_variable(ident, type)
        if type.kind_of? Array
          ArrayVariable.new ident, type
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

    class ArrayVariable < RubyVariable
      def initialize(key, val)
        super key, val
        @generic_type = RubyVariable::convert_to_variable("#{@symbol}_inarray", val[0])
      end

      def default_value
        []
      end

      def to_required_value_from(value_expression)
          "#{value_expression}.to_a.map{|v| #{@generic_type.to_value_from('v')}}"
      end
    end

    class StringVariable < RubyVariable
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

    class IntegerVariable < RubyVariable
      def default_value
        0
      end

      def to_required_value_from(value_expression)
        "#{value_expression}.to_i"
      end
    end

    class DoubleVariable < RubyVariable
      def default_value
        0
      end

      def to_required_value_from(value_expression)
        "#{value_expression}.to_f"
      end
    end

    class BoolVariable < RubyVariable
      def default_value
        false
      end

      def to_required_value_from(value_expression)
        "(#{value_expression} ? true : false)"
      end
    end

    class CustomVariable < RubyVariable
      def initialize(ident, type)
        super(ident, type)
        @class_name = type
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
          line "module #{namespace}", 'end' do
            super namespace
          end
        else
          super namespace
        end
      end

      def output_common_functions
        line File.read(File.expand_path('../ruby_common_scripts.rb', __FILE__)).split /\n/
      end

      def convert_attrs_to_variable(attrs)
        ret = []
        attrs.each do |ident, type|
          ret << RubyVariable::convert_to_variable(ident, type)
        end
        ret
      end

      # For Ruby
      def create_class(class_name, attrs)
        dpp attrs
        variables = convert_attrs_to_variable attrs
        line "class #{class_name} < JsonGenEntityBase", 'end' do
          # accessor
          line 'attr_accessor ' + variables.map {|t| ":#{t.ident}"}. join(', ')
          new_line
          make_constructor variables
          new_line
          make_to_json variables
          new_line
          make_from_json variables
        end
      end

      def make_constructor(variables)
        line 'def initialize', 'end' do
          variables.each do |var|
            if var.optional
              line "@#{var.ident} = nil"
            else
              line "@#{var.ident} = #{var.default_value_expression}"
            end
          end
        end
      end

      def make_to_json(variables)
        line 'def to_json_hash', 'end' do
          line 'hash = {}'
          variables.each do |var|
            value_expression = "@#{var.ident}"
            convert_expression = var.to_hash_with value_expression
            line = "hash[:#{var.ident}] = #{convert_expression}"
            if var.optional
              line += " unless @#{var.ident} == nil"
            end
            line line
          end
          line 'encode(hash)'
        end
      end

      def make_from_json(variables)
        line 'def from_json_hash(hash)', 'end' do
          variables.each do |var|
            value_expression = "hash['#{var.ident}']"
            convert_expression = var.to_value_from(value_expression)
            line = "@#{var.ident} = #{convert_expression}"
            if var.optional
              line += " if hash.include? '#{var.ident}'"
            end
            line line
          end
          line 'self'
        end
      end
    end
  end
end
