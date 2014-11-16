module MySpec
  class JsonGenEntityBase
    def encode(obj)
      if obj.kind_of? Array
        obj.map {|x| encode(x)}
      elsif obj.kind_of? Hash
        ret = {}
        obj.each do |k, v|
          ret[k] = encode(v)
        end
        ret
      elsif obj.kind_of? JsonGenEntityBase
        obj.to_json_hash
      else
        obj
      end
    end
  end

  class Item < JsonGenEntityBase
    attr_accessor :name, :price, :on_sale

    def initialize
      @name = ''
      @price = 0
      @on_sale = nil
    end

    def to_json_hash
      hash = {}
      hash[:name] = @name
      hash[:price] = @price
      hash[:on_sale] = (@on_sale == nil ? nil : @on_sale) unless @on_sale == nil
      encode(hash)
    end

    def from_json_hash(hash)
      @name = hash['name'].to_s
      @price = hash['price'].to_i
      @on_sale = (hash['on_sale'] == nil ? nil : (hash['on_sale'] ? true : false)) if hash.include? 'on_sale'
      self
    end
  end

  class User < JsonGenEntityBase
    attr_accessor :name, :birthday

    def initialize
      @name = ''
      @birthday = nil
    end

    def to_json_hash
      hash = {}
      hash[:name] = @name
      hash[:birthday] = (@birthday == nil ? nil : @birthday) unless @birthday == nil
      encode(hash)
    end

    def from_json_hash(hash)
      @name = hash['name'].to_s
      @birthday = (hash['birthday'] == nil ? nil : hash['birthday'].to_s) if hash.include? 'birthday'
      self
    end
  end

  class Order_comments < JsonGenEntityBase
    attr_accessor :user, :message, :deleted

    def initialize
      @user = User.new
      @message = ''
      @deleted = nil
    end

    def to_json_hash
      hash = {}
      hash[:user] = @user
      hash[:message] = @message
      hash[:deleted] = (@deleted == nil ? nil : @deleted) unless @deleted == nil
      encode(hash)
    end

    def from_json_hash(hash)
      @user = User.new.from_json_hash(hash['user'])
      @message = hash['message'].to_s
      @deleted = (hash['deleted'] == nil ? nil : (hash['deleted'] ? true : false)) if hash.include? 'deleted'
      self
    end
  end

  class Order < JsonGenEntityBase
    attr_accessor :user, :items, :comments

    def initialize
      @user = User.new
      @items = []
      @comments = []
    end

    def to_json_hash
      hash = {}
      hash[:user] = @user
      hash[:items] = @items
      hash[:comments] = @comments
      encode(hash)
    end

    def from_json_hash(hash)
      @user = User.new.from_json_hash(hash['user'])
      @items = hash['items'].to_a.map{|v| Item.new.from_json_hash(v)}
      @comments = hash['comments'].to_a.map{|v| Order_comments.new.from_json_hash(v)}
      self
    end
  end

end