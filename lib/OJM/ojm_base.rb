# coding: utf-8

module Yousei::OJMGenerator
  class GeneratorBase
    include Yousei::Common
    include Yousei::OutputFormatter

    def initialize(opts={})
      initialize_formatter opts
      @indent_width = 4
      @ext = 'txt'
      @sub_dir = 'entity'
    end

    # @param [Hash] def_hash
    def generate(def_hash, opts = {})
      with_namespace opts[:namespace] do
        @writer.change_filename "#{entity_class :Common}.#{@ext}", @sub_dir
        output_common_functions

        # dpp def_hash
        definitions = replace_anonymous def_hash
        # dpp definitions
        definitions = customize_definitions definitions
        definitions.each do |class_name, attrs|
          @writer.change_filename "#{class_name}.#{@ext}", @sub_dir
          create_class(class_name, attrs)
          outputln
        end
      end
    end

    def with_namespace(namespace)
      yield(namespace) if block_given?
    end

    def output_include
    end

    def output_common_functions
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

    def customize_definitions(definitions)
      definitions
    end

    # @param [Hash] classes
    # @param [String] class_name
    # @param [Hash] attrs
    def replace_attrs(classes, class_name, attrs)
      new_attrs = {}
      attrs.each do |key, val|
        new_attrs[key] = replace_attr_val(classes, class_name, key, val)
      end
      new_attrs
    end

    def replace_attr_val(classes, class_name, key, val)
      if val.kind_of? Hash
        new_class_name = make_auto_generate_class_name class_name, key
        classes[new_class_name] = replace_attrs classes, new_class_name, val
        val = new_class_name
      elsif val.kind_of? Array
        raise 'Array can contain only 1 Type!' if val.size > 1
        val = [replace_attr_val(classes, class_name, key, val[0])]
      end
      val
    end

    # @param [String] base_class_name
    # @param [String] key_name
    def make_auto_generate_class_name(base_class_name, key_name)
      "#{base_class_name}_#{pure_symbol(key_name)}"
    end
  end
end
