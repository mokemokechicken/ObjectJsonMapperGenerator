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
      output s
      new_line
      if block_given?
        incr_indent
        yield
        decr_indent
        outputln after_block if after_block
      end
    end
  end

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

