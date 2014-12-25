#!/usr/bin/env ruby
# coding: utf-8


require 'optparse'
require 'yaml'
require 'stringio'
require_relative File.expand_path('../../lib/yousei', __FILE__)

params = {}

opt = OptionParser.new
opt.on('-v', 'Verbose') {|v| params[:verbose] = v }
opt.on('-c filename', 'Specify Structure YAML File') {|v| params[:config] = v }
opt.on('-l language', %w(ruby swift), 'ruby|swift') {|v| params[:language] = v }
opt.on('-t type', %w(json api ds), 'json|api|ds') {|v| params[:type] = v }
opt.on('-n [namespace]', 'Specify Namespace of OJM codes') {|v| params[:namespace] = v }
opt.on('-o [output filename]', 'Specify output filename.') {|v| params[:output] = v }
opt.on('-d [output dir]', 'Specify output dir.') {|v| params[:dir] = v }

opt.parse!(ARGV)

config_file = params[:config]

if !params[:config] || !params[:language]
  puts opt.help
  exit(1)
end


hash = YAML.load(File.read(config_file))
out =
  if params[:dir]
    Yousei::DirFileWriter.new(dir: params[:dir])
  elsif params[:output]
    Yousei::FileWriter.new(filename: params[:output])
  else
    Yousei::IOWriter.new(io: STDOUT)
  end

debug_output =
    if params[:verbose]
      STDERR
    else
      StringIO.new
    end

gen_class = case [params[:language], params[:type]]
              when %w(ruby json) then Yousei::OJMGenerator::Ruby::RubyOJMGenerator
              when %w(swift json) then Yousei::OJMGenerator::Swift::SwiftOJMGenerator
              when %w(swift api) then Yousei::APIGenerator::Swift::SwiftGenerator
              when %w(swift ds) then Yousei::DataServiceGenerator::Swift::SwiftGenerator
              else
                puts "unsupported type #{params[:type]} and language #{params[:language]}"
                exit 1
            end

obj = gen_class.new writer: out, debug_output: debug_output
obj.generate hash, namespace: params[:namespace]
