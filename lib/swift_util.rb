module Yousei
  module SwiftUtil
    def to_swift_identifier
      "`#{self}`"
    end
    alias_method :si, :to_swift_identifier

    def to_swift_literal
      if self.kind_of?(String) || self.kind_of?(Symbol)
        '"' + to_s + '"'
      else
        to_s
      end
    end
    alias_method :sl, :to_swift_literal
  end

  def self.enable_swift_feature
    Object.class_eval { include Yousei::SwiftUtil }
  end
end