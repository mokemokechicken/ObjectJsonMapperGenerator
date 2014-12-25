module Yousei
  class Writer
    def initialize(opts=nil)
      @open_new_file_hook = nil
    end

    def print(s)
      @writer.print s
    end

    def change_filename(new_filename, new_dir=nil)
      # NO Operation
    end

    def register_hook_open_new_file(&block)
      @open_new_file_hook = block
    end

    private
    def fire_after_open_new_file(info)
      @open_new_file_hook.call(info) if @open_new_file_hook
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
      @sub_dir = nil
      @filename = opts[:filename] || 'yousei'
    end

    def change_filename(new_filename, sub_dir=nil)
      @sub_dir = sub_dir
      @filename = new_filename
      Dir.mkdir write_dir unless Dir.exist? write_dir
      setup_writer
    end

    private

    def setup_writer
      @writer.close if @writer && !@writer.closed?
      @writer = File.open(abs_path, is_new? ? 'w' : 'a')
      fire_after_open_new_file(dir: write_dir, filename: @filename, abs_path: abs_path)  if is_new?
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

    def write_dir
      "#{@dir}/#{@sub_dir}"
    end

    def abs_path
      File.absolute_path(@filename, write_dir)
    end
  end
end
