require 'yaml'

hash = YAML.load(<<-EOY)

Common: &common
  id: String
  name: String

Item:
  <<: *common
  price: Int


EOY

p hash
