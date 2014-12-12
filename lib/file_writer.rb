module Yousei
  class Writer
    def print(s)
      @writer.print s
    end

    def change_filename(new_filename, new_dir=nil)
      # NO Operation
    end
  end

  class IOWriter < Writer
    def initialize(opts)
      @writer = opts[:io]
    end
  end

  class FileWriter < Writer
    def initialize(opts)
      @writer = File.open(opts[:filename], 'w')
    end
  end

  class DirFileWriter < Writer
    def initialize(opts)
      @opened = []
      @dir = opts[:dir]
      @filename = opts[:filename] || 'yousei'
    end

    def change_filename(new_filename, new_dir=nil)
      @dir = new_dir if new_dir
      @filename = new_filename
      setup_writer
    end

    private

    def setup_writer
      @writer.close if @writer && !@writer.closed?
      mode = @opened.include? abs_path ? 'a' : 'w'
      @writer = File.open(abs_path, mode)
      add_opened abs_path
    end

    def add_opened(path)
      unless @opened.include? path
        @opened << path
      end
    end

    def abs_path
      File.absolute_path(@filename, @dir)
    end

  end

end
