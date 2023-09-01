class User < ApplicationRecord
  # has_secure_password
  self.inheritance_column = :_type_bla_bla

  self.table_name = "Users"
  self.primary_key = "Id"

  def fullname
    "#{self.FirstName} #{self.LastName}"
  end

end
