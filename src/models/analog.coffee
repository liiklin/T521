schema =
  group_id:
    type: String
    required: true
  id:
    type: String
    required: false
    unique: true
  cores:
    type: Array
    required: false
    default: []

module.exports = schema
