module Yousei
  module OutputFormatter
    def initialize_formatter(opts={})
      @indent_width = 4
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
        write((' ' * (@indent * @indent_width)) + s.to_s)
      end
    end

    def new_line
      write "\n"
    end

    def outputln(s='', after_block=nil)
      unless s.nil?
        output s
        new_line
      end

      if block_given?
        incr_indent
        yield
        decr_indent
        if after_block != nil
          outputln after_block
        else
          outputln '}' if s.end_with? '{'
        end
      end
    end

    alias_method :line, :outputln
  end

  module OutputFormatterClasses
    class BufferedOutputFormatter
      attr_accessor :string_array
      include OutputFormatter

      def initialize(opts={})
        @string_array = []
        initialize_formatter opts
        @line = ''
      end

      def write(s)
        @line += s
      end

      def new_line
        @string_array << @line
        @line = ''
      end
    end
  end

  module Common
    def pure_symbol(key)
      key.to_s.gsub(/[?]/, '')
    end

    def optional?(key)
      key =~ /\?$/
    end
  end

  class Variable
    include Common
    include OutputFormatterClasses

    attr_accessor :ident, :type, :optional

    def initialize(ident, type)
      @ident = pure_symbol ident
      @type = type
      @optional = optional? ident
    end

    def to_value_from(value_expression)
      value_expression
    end
  end
end

class String
  def camelize(uppercase_first_letter = true)
    if uppercase_first_letter
      self.split('_').each {|s| s.capitalize! }.join('')
    else
      x, xs = self.split('_', 2)
      x + (xs || '').camelize
    end
  end
end