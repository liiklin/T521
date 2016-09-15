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
    default: "orphan"
  times:
    type: Number
    required: true
    default: 1

module.exports = schema
