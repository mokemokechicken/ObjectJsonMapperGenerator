=begin
Book:
  authors: [Author]
  title: String
  note?: String
  option:
    hoge?: String
    hara?: Bool
=end

class Book < Base
  attr_accessor :authors, :title, :note, :option

  class Book_0 < Base
    attr_accessor :hoge?, :hara?

    def initialize
      @hoge = nil
      @hara = nil
    end

    def to_json_hash
      hash = {}
      # ...
    end

  end

  def initialize
    @authors = []
    @title = ''
    @note = nil
    @option = nil
  end

  def to_json_hash
    hash = {}
    hash[:authors] = @authors
    hash[:title] = @title
    hash[:note] = @note unless @note == nil
    encode(hash)
  end

  # @param [Hash] hash
  def from_json_hash(hash)
    @authors = hash['authors'].to_a
    @title = hash['title'].to_s
    @note = hash['note'] if hash.include? 'note'
    @option = Book_0.new.from_json hash['option'] if hash.include? 'option'
  end
end

class Author < Base
  attr_accessor :name, :age, :sex

  def initialize
    @name = @age = @sex = nil
  end

  def to_json_hash
    hash = {}
    hash[:name] = @name
    hash[:age] = @age
    hash[:sex] = @sex
    encode(hash)
  end
end
