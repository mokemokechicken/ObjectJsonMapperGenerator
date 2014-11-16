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
  csv:
    -
      - id: Int
        name: String
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
  ],
  "csv": [
    [ {"id": 1, "name": "name1"} ],
    [ {"id": 2, "name": "name2"}, {"id": 22, "name": "name22"} ]
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
    puts @code
    expect { eval(@code) }.not_to raise_error
  end

  it 'can parse JSON' do
    eval(@code)
    expect { MySpec::Order.new.from_json_hash(sample_json) }.not_to raise_error
  end

  describe 'Order Decoder' do
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
      expect(@order.comments[0].user.name).to eq 'who1'
      expect(@order.comments[0].user.birthday).to be_nil
      expect(@order.comments[0].message).to eq 'this shop is good!'
      expect(@order.comments[0].deleted).to be_nil

      expect(@order.comments[1].user.name).to eq 'who2'
      expect(@order.comments[1].user.birthday).to be_nil
      expect(@order.comments[1].message).to eq 'this shop is bad!'
      expect(@order.comments[1].deleted).to eq true
    end

    it 'should parse csv info' do
      expect(@order.csv[0][0].id).to eq 1
      expect(@order.csv[0][0].name).to eq 'name1'

      expect(@order.csv[1][0].id).to eq 2
      expect(@order.csv[1][0].name).to eq 'name2'
      expect(@order.csv[1][1].id).to eq 22
      expect(@order.csv[1][1].name).to eq 'name22'
    end
  end

  describe 'Order Encoder' do
    before do
      @order = MySpec::Order.new.from_json_hash(sample_json)
      @json = @order.to_json_hash
      puts @json
    end

    it 'should have 3 items and 2 comments' do
      expect(@json[:items].size).to eq 3
      expect(@json[:comments].size).to eq 2
    end

    it 'should have collect user info' do
      expect(@json[:user][:name]).to eq 'Ken Morishita'
      expect(@json[:user][:birthday]).to eq '2011/11/11'
    end

    it 'should have collect items info' do
      expect(@json[:items][0][:name]).to eq 'Book1'
      expect(@json[:items][0][:price]).to eq 500
      expect(@json[:items][0][:on_sale]).to eq true

      expect(@json[:items][1][:name]).to eq 'Book2'
      expect(@json[:items][1][:price]).to eq 200
      expect(@json[:items][1][:on_sale]).to eq false

      expect(@json[:items][2][:name]).to eq 'Book3'
      expect(@json[:items][2][:price]).to eq 900
      expect(@json[:items][2][:on_sale]).to be_nil
    end

    it 'should have collect comments info' do
      expect(@json[:comments][0][:user][:name]).to eq 'who1'
      expect(@json[:comments][0][:message]).to eq 'this shop is good!'
      expect(@json[:comments][0][:deleted]).to be_nil

      expect(@json[:comments][1][:user][:name]).to eq 'who2'
      expect(@json[:comments][1][:message]).to eq 'this shop is bad!'
      expect(@json[:comments][1][:deleted]).to eq true
    end
    it 'should parse csv info' do
      expect(@json[:csv][0][0][:id]).to eq 1
      expect(@json[:csv][0][0][:name]).to eq 'name1'
      expect(@json[:csv][1][0][:id]).to eq 2
      expect(@json[:csv][1][0][:name]).to eq 'name2'
      expect(@json[:csv][1][1][:id]).to eq 22
      expect(@json[:csv][1][1][:name]).to eq 'name22'
    end

  end
end

