class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :intake_repairs, class_name: "Repair", foreign_key: :intake_user_id, dependent: :restrict_with_error
  belongs_to :staff, optional: true

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  enum :role, { owner: "owner", mechanic: "mechanic", counter: "counter" }, default: :counter

  validates :email_address, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP },
    uniqueness: { case_sensitive: false }
  validates :password, length: { minimum: 10, too_short: "must be at least 10 characters." }, allow_nil: true

  def display_name
    staff&.name || email_address
  end
end
