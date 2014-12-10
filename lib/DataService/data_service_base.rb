module Yousei::DataServiceGenerator
  class GeneratorBase
    include Yousei::OutputFormatter

    def initialize(opts={})
      initialize_formatter opts
      @indent_width = 4
    end

    # @param [Hash] definitions
    def generate(definitions, opts=nil)
      fetch_definitions definitions
    end

    def fetch_definitions(definitions)
      @definitions = definitions
      @entity_def = definitions['entity']
      @api_def = definitions['api']
      @api_prefix = definitions['api_prefix'].to_s
      @entity_prefix = definitions['entity_prefix'].to_s
      @data_service_prefix = definitions['data_service_prefix'].to_s
    end
  end
end
