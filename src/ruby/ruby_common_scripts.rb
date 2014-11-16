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
