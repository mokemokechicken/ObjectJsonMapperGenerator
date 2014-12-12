module Yousei
  class Writer
    def initialize(opts=nil)
      @open_new_file_hooks = []
    end

    def print(s)
      @writer.print s
    end

    def change_filename(new_filename, new_dir=nil)
      # NO Operation
    end

    def register_hook_open_new_file(&block)
      @open_new_file_hooks << block
    end

    private
    def fire_after_open_new_file(info)
      @open_new_file_hooks.each do |block|
        block.call(info)
      end
    end
  end

  class IOWriter < Writer
    def initialize(opts)
      super(opts)
      @writer = opts[:io]
    end
  end

  class FileWriter < Writer
    def initialize(opts)
      super(opts)
      @writer = File.open(opts[:filename], 'w')
    end
  end

  class DirFileWriter < Writer
    def initialize(opts)
      super(opts)
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
      @writer = File.open(abs_path, is_new? ? 'w' : 'a')
      fire_after_open_new_file(dir: @dir, filename: @filename, abs_path: abs_path)  if is_new?
      add_opened abs_path
    end

    def add_opened(path)
      unless @opened.include? path
        @opened << path
      end
    end

    def is_new?
      !(@opened.include? abs_path)
    end

    def abs_path
      File.absolute_path(@filename, @dir)
    end
  end
end
