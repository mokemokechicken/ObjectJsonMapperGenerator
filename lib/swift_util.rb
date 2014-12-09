module Yousei::Swift
  module SwiftUtil
    SWIFT_KEYWORDS = %w(
        class deinit enum extension func import init internal let operator private protocol public
        static struct subscript typealias var
        break case continue default do else fallthrough for if in return switch where while
        as dynamicType false is nil self Self super true
        associativity convenience dynamic didSet final get infix inout lazy left mutating none nonmutating
        optional override postfix precedence prefix Protocol required right set Type unowned weak willSet
      )

    def to_swift_identifier
      if SWIFT_KEYWORDS.include? self.to_s
        "`#{self}`"
      else
        self.to_s
      end
    end

    alias_method :si, :to_swift_identifier

    def to_swift_variable_name
      self.to_s.camelize(false).to_swift_identifier
    end

    alias_method :sv, :to_swift_variable_name

    def to_swift_literal
      if self.kind_of?(String) || self.kind_of?(Symbol)
        '"' + to_s + '"'
      else
        to_s
      end
    end

    alias_method :sl, :to_swift_literal
  end

  def enable_swift_feature
    Object.class_eval { include Yousei::Swift::SwiftUtil }
  end

  ################# Variables ####################
  class SwiftVariable < Yousei::Variable
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
    alias_method :code_name, :variable_name_in_code

    def type_expression_with_optional
      @optional ? "#{type_expression}?" : type_expression
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
end