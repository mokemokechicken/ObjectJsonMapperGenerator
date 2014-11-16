# coding: utf-8

module OJMGenerator
  module Common
    def pure_symbol(key)
      key.to_s.gsub(/[?]/, '')
    end

    def optional?(key)
      key =~ /\?$/
    end
  end

  class JsonType
    include Common

    attr_accessor :key, :val, :optional

    def initialize(key, val)
      @key = pure_symbol key
      @val = val
      @optional = optional? key
    end

    def to_value_from(value_expression)
      value_expression
    end
  end

  class GeneratorBase
    include Common

    @@indent_width = 4

    def initialize(opts={})
      @indent = 0
      @writer = opts[:writer] || STDOUT
      @debug_output = opts[:debug_output] || STDERR
    end

    def incr_indent
      ret = @indent
      @indent += 1
      ret
    end

    def decr_indent
      ret = @indent
      @indent -= 1
      ret
    end

    def dpp(s)
      @debug_output.puts s.inspect
    end

    def write(s)
      @writer.print s.to_s
    end

    def output(s)
      if s.kind_of? Array
        s.each do |line|
          outputln line
        end
      else
        write((' ' * (@indent * @@indent_width)) + s.to_s)
      end
    end

    def new_line
      write "\n"
    end

    def outputln(s='', after_block=nil)
      output s
      new_line
      if block_given?
        incr_indent
        yield
        decr_indent
        outputln after_block if after_block
      end
    end

    # @param [Hash] def_hash
    def generate(def_hash, opts = {})
      with_namespace opts[:namespace] do
        output_common_functions
        dpp def_hash
        definitions = replace_anonymous def_hash
        dpp definitions
        definitions.each do |class_name, attrs|
          create_class(class_name, attrs)
          outputln
        end
      end
    end

    def with_namespace(namespace)
      yield(namespace) if block_given?
    end

    def output_common_functions
      outputln '// Override output_common_functions methods! for output Common Functions'
    end

    # @param [Hash] definitions
    def replace_anonymous(definitions)
      classes = {}
      definitions.each do |class_name, attrs|
        new_attrs = replace_attrs classes, class_name, attrs
        classes[class_name] = new_attrs
      end
      classes
    end

    # @param [Hash] classes
    # @param [String] class_name
    # @param [Hash] attrs
    def replace_attrs(classes, class_name, attrs)
      new_attrs = {}
      attrs.each do |key, val|
        if val.kind_of? Hash
          new_class_name = make_auto_generate_class_name class_name, key
          classes[new_class_name] = replace_attrs classes, new_class_name, val
          val = new_class_name
        elsif val.kind_of? Array
          raise 'Array can contain only 1 Type!' if val.size > 1
          if val[0].kind_of? Hash
            new_class_name = make_auto_generate_class_name class_name, key
            classes[new_class_name] = replace_attrs classes, new_class_name, val[0]
            val = [new_class_name]
          end
        end

        new_attrs[key] = val
      end
      new_attrs
    end

    # @param [String] base_class_name
    # @param [String] key_name
    def make_auto_generate_class_name(base_class_name, key_name)
      "#{base_class_name}_#{pure_symbol(key_name)}"
    end
  end
end