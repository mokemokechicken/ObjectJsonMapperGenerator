module Yousei::APIGenerator
  class GeneratorBase
    include Yousei::OutputFormatter

    def initialize(opts={})
      initialize_formatter opts
      @indent_width = 4
    end

    # @param [Hash] definitions
    def generate(definitions, opts = {})
      fetch_definitions definitions
      create_entity if @entity_def
      create_api 
    end

    def fetch_definitions(definitions)
      @definitions = definitions
      @entity_def = definitions['entity']
      @api_def = definitions['api']
      @api_prefix = definitions['api_prefix'].to_s
      @entity_prefix = definitions['entity_prefix'].to_s
    end

    def create_entity
    end
    
    def create_api
    end

  end
end
