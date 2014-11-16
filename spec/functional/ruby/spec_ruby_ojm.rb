# coding: utf-8
require 'spec/spec_helper'
require 'yaml'

yaml_str = <<YAML
Item:
  name: String
  price: Int
  on_sale: Bool

User:
  name: String
  birthday?: String

Order:
  user: User
  items: [Item]
  comments: [{user: User, message: String, deleted?: Bool}]
YAML

structure = YAML.load(yaml_str)


describe 'Ruby OJM Function' do
  before do
    @gen = OJMGenerator::Ruby::RubyOJMGenerator.new
  end

  describe 'Generated Syntax is OK' do
    buffer = StringIO.new
    @gen.generate structure, namespace: 'MySpec', writer: buffer
    expect(true).to be_true
  end
end