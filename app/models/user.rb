# == Schema Information
#
# Table name: Users
#
#  Id                      :integer          not null, primary key
#  Login                   :text(4294967295) not null
#  Password                :text(4294967295) not null
#  Salt                    :text(4294967295) not null
#  FirstName               :text(4294967295)
#  LastName                :text(4294967295)
#  IsActive                :boolean          not null
#  Role                    :integer          not null
#  email                   :string(255)      default(""), not null
#  encrypted_password      :string(255)      default(""), not null
#  reset_password_token    :string(255)
#  reset_password_sent_at  :datetime
#  remember_created_at     :datetime
#  sign_in_count           :integer          default(0), not null
#  current_sign_in_at      :datetime
#  last_sign_in_at         :datetime
#  current_sign_in_ip      :string(255)
#  last_sign_in_ip         :string(255)
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  type                    :string(255)
#  Description             :text(4294967295)
#  LastPasswordChangeAt    :datetime
#  PasswordChangeRevokedAt :datetime
#  password_changed_at     :datetime
#  LastSelectedCertLabel   :text(4294967295)
#  HasSmartCard            :boolean          not null
#  TokenSerialNumber       :text(4294967295)
#
class User < ApplicationRecord
  extend Mobility
  # has_secure_password
  self.inheritance_column = :_type_bla_bla

  self.table_name = "Users"
  self.primary_key = "Id"

  translates :FirstName, type: :string, default: -> { read_attribute(:FirstName) }
  translates :LastName, type: :string, default: -> { read_attribute(:LastName) }
  translates :Description, type: :string, default: -> { read_attribute(:Description) }

  # See Project#Name= for why this keys off an explicit locale: kwarg rather than
  # ambient I18n.locale (app default locale is :en, but these columns hold Polish
  # text) — a bare assignment must always land in the native column.
  def FirstName=(value, locale: nil, **options)
    explicit_locale = locale&.to_sym
    if explicit_locale.nil? || explicit_locale == :pl
      write_attribute(:FirstName, value)
    else
      super(value, locale: locale, **options)
    end
  end

  def LastName=(value, locale: nil, **options)
    explicit_locale = locale&.to_sym
    if explicit_locale.nil? || explicit_locale == :pl
      write_attribute(:LastName, value)
    else
      super(value, locale: locale, **options)
    end
  end

  def Description=(value, locale: nil, **options)
    explicit_locale = locale&.to_sym
    if explicit_locale.nil? || explicit_locale == :pl
      write_attribute(:Description, value)
    else
      super(value, locale: locale, **options)
    end
  end

  def fullname
    "#{self.FirstName} #{self.LastName}"
  end

end
