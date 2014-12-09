module Yousei
  module SwiftUtil
    SWIFT_KEYWORDS = %w(
      class deinit enum extension func import init internal let operator private protocol public
      static struct subscript typealias var
      break case continue default do else fallthrough for if in return switch where while
      as dynamicType false is nil self Self super true
      associativity convenience dynamic didSet final get infix inout lazy left mutating none nonmutating
      optional override postfix precedence prefix Protocol required right set Type unowned weak willSet
    )

    def to_swift_identifier
      if SWIFT_KEYWORDS.include? self.to_s
        "`#{self}`"
      else
        self.to_s
      end
    end
    alias_method :si, :to_swift_identifier

    def to_swift_variable_name
      self.to_s.camelize(false).to_swift_identifier
    end
    alias_method :sv, :to_swift_variable_name

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