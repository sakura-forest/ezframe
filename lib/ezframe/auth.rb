class User
  attr_accessor :id, :password

  USER_MAPPING = {
    kamachi: 'kamakamachi',
    hoge: 'fuga',
  }

  def initialize(id, pass)
    self.id = id
    self.passworkd = pass
  end

  def self.get(id)
    new(id, USER_MAPPING[id.to_sym])
  end

  def self.authenticate(id, pass)
    return false unless password = USER_MAPPING[id.to_sym]
    !!(password == pass)
  end
end