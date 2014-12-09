module Yousei::APIGenerator
  class GeneratorBase
    include Yousei::OutputFormatter

    def initialize(opts={})
      initialize_formatter opts
      @indent_width = 4
    end

    # @param [Hash] definitions
    def generate(definitions, opts=nil)
      fetch_definitions definitions
      create_entity(prefix: @entity_prefix, def: @entity_def) if @entity_def
      create_api(prefix: @api_prefix, def: @api_def)
    end

    def fetch_definitions(definitions)
      @definitions = definitions
      @entity_def = definitions['entity']
      @api_def = definitions['api']
      @api_prefix = definitions['api_prefix'].to_s
      @entity_prefix = definitions['entity_prefix'].to_s
    end

    def create_entity(opts)
    end
    
    def create_api(opts)
    end

  end
end
