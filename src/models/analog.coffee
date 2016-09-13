schema =
  group_id:
    type: String
    required: true
  id:
    type: String
    required: false
    unique: true
  cores:
    type: String
    required: false

module.exports = schema
