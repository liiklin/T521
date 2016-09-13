schema =
  group_id:
    type: String
    required: true
  id:
    type: String
    required: true
    unique: true
  state:
    type: String
    required: true
  times:
    type: Number
    required: true

module.exports = schema
