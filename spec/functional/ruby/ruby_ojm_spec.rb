# coding: utf-8
require 'spec_helper'
require 'yaml'
require 'stringio'
require 'json'

yaml_str = <<YAML
Item:
  name: String
  price: Int
  on_sale?: Bool

User:
  name: String
  birthday?: String

Order:
  user: User
  items: [Item]
  comments:
    - user: User
      message: String
      deleted?: Bool
YAML

order_json  = <<JSON
{
  "user": {"name": "Ken Morishita", "birthday": "2011/11/11"},
  "items": [
    {"name": "Book1", "price": 500, "on_sale": true},
    {"name": "Book2", "price": 200, "on_sale": false},
    {"name": "Book3", "price": 900}
  ],
  "comments": [
    {"user": {"name": "who1"}, "message": "this shop is good!"},
    {"user": {"name": "who2"}, "message": "this shop is bad!", "deleted": true}
  ]
}
JSON

structure = YAML.load(yaml_str)
sample_json = JSON.parse(order_json)

describe 'Ruby OJM Function' do
  before do
    @buffer = StringIO.new
    dev_null = StringIO.new
    @gen = OJMGenerator::Ruby::RubyOJMGenerator.new writer: @buffer, debug_output: dev_null
    @gen.generate structure, namespace: 'MySpec'
    @code = @buffer.string
  end

  it 'Generated Syntax is OK' do
    expect { eval(@code) }.not_to raise_error
  end

  it 'can parse JSON' do
    eval(@code)
    expect { MySpec::Order.new.from_json_hash(sample_json) }.not_to raise_error
  end

  describe 'Order Parser' do
    before do
      @order = MySpec::Order.new.from_json_hash(sample_json)
    end

    it 'should have 2 items' do
      expect(@order.items.size).to eq 2
    end
  end
end

