#!/usr/bin/env ruby
# coding: utf-8


require 'optparse'
require 'yaml'
require 'stringio'
require_relative File.expand_path('../../lib/ojm_generator', __FILE__)

params = {}

opt = OptionParser.new
opt.on('-v', 'Verbose') {|v| params[:verbose] = v }
opt.on('-c filename', 'Specify Structure YAML File') {|v| params[:config] = v }
opt.on('-l language', %w(ruby swift)) {|v| params[:language] = v }
opt.on('-n [namespace]', 'Specify Namespace of OJM codes') {|v| params[:namespace] = v }
opt.on('-o [output filename]', 'Specify output filename.') {|v| params[:output] = v }

opt.parse!(ARGV)

config_file = params[:config]

if !params[:config] || !params[:language]
  puts opt.help
  exit(1)
end


hash = YAML.load(File.read(config_file))
out =
  if params[:output]
    File.open(params[:output], 'w')
  else
    STDOUT
  end

debug_output =
    if params[:verbose]
      STDERR
    else
      StringIO.new
    end

gen_class = case params[:language]
              when 'ruby'
                Yousei::OJMGenerator::Ruby::RubyOJMGenerator

              when 'swift'
                Yousei::OJMGenerator::Swift::SwiftOJMGenerator
            end

obj = gen_class.new writer: out, debug_output: debug_output
obj.generate  hash, namespace: params[:namespace]
