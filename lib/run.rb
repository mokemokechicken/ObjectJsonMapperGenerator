require 'yaml'
require_relative 'ruby/ruby_generator'

str = <<EOY
Book:
  authors: [Author]
  title: String
  note?: String
  option?:
    hoge?: String
    hara?: Bool

Author:
  name: String
  sex: String
  age?: Int
  test: Bool
EOY

dom = YAML.load(str)

OJMGenerator::Ruby::RubyOJMGenerator.new.generate dom, namespace: 'MyApp'
