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

    it 'should have 3 items and 2 comments' do
      expect(@order.items.size).to eq 3
      expect(@order.comments.size).to eq 2
    end

    it 'should have collect user info' do
      user = @order.user
      expect(user.name).to eq 'Ken Morishita'
      expect(user.birthday).to eq '2011/11/11'
    end

    it 'should have collect items info' do
      expected = [
          {'name' => 'Book1', 'price' => 500, 'on_sale' => true},
          {'name' => 'Book2', 'price' => 200, 'on_sale' => false},
          {'name' => 'Book3', 'price' => 900}
      ]
      expect(@order.items[0].name).to eq 'Book1'
      expect(@order.items[0].price).to eq 500
      expect(@order.items[0].on_sale).to eq true

      expect(@order.items[1].name).to eq 'Book2'
      expect(@order.items[1].price).to eq 200
      expect(@order.items[1].on_sale).to eq false

      expect(@order.items[2].name).to eq 'Book3'
      expect(@order.items[2].price).to eq 900
      expect(@order.items[2].on_sale).to be_nil
    end

    it 'should have collect comments info' do
      expected = [
          {'user' => {'name' => 'who1'}, 'message' => 'this shop is good!'},
          {'user' => {'name' => 'who2'}, 'message' => 'this shop is bad!', 'deleted' => true}
      ]
      expect(@order.comments[0].user.name).to eq 'who1'
      expect(@order.comments[0].user.birthday).to be_nil
      expect(@order.comments[0].message).to eq 'this shop is good!'
      expect(@order.comments[0].deleted).to be_nil

      expect(@order.comments[1].user.name).to eq 'who2'
      expect(@order.comments[1].user.birthday).to be_nil
      expect(@order.comments[1].message).to eq 'this shop is bad!'
      expect(@order.comments[1].deleted).to eq true
    end
  end
end

