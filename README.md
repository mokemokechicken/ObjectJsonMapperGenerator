About
=========

Code Generator of JSON <-> Object Mapping.
The Specification is writted with simple YAML.

Example
=========

```yaml
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
```

```json
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
```