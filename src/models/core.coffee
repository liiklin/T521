schema =
  group_id:
    type: String
    required: true
  id:
    type: String
    required: true
    unique: true
  analogs:
    type: Array
    required: false

module.exports = schema
