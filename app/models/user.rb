class User < ApplicationRecord
  attr_accessor :remove_profile
  has_one_attached :profile_picture
  rolify
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  def self.ransackable_attributes(auth_object = nil)
    [ "f_name", "m_name", "l_name", "employee_id", "job_title", "employment_status", "role", "salary" ]
  end

  validates :email, presence: true, uniqueness: { case_sensitive: true }, format: { 
            with: /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]{3,}\z/i, message: "must be a valid email address" }
  
  validates :employment_status, :gender, presence: true
  validates :f_name, presence: true, length: { minimum: 2 }, if: -> { f_name.present? }, format: { with: /\A[a-zA-Z]+\z/, message: "only allows letters" }
  validates :m_name, presence: true, length: { minimum: 2 }, if: -> { m_name.present? }, format: { with: /\A[a-zA-Z]+\z/, message: "only allows letters" }
  validates :l_name, presence: true, length: { minimum: 2 }, if: -> { l_name.present? }, format: { with: /\A[a-zA-Z]+\z/, message: "only allows letters" }
  validates :job_title, presence: true, length: { minimum: 2 }, if: -> { job_title.present? }, format: { with: /\A[a-zA-Z]+\z/, message: "only allows letters" }
  validates :employee_id, presence: true, numericality: { only_integer: true }, format: { with: /\A\d+\z/, message: "only allows numbers" }
  validates :employee_id, uniqueness: true
  validates :salary, presence: true, length: { minimum: 4 }, numericality: { only_integer: true }, format: { with: /\A\d+\z/, message: "only allows numbers" }

  validates :password, format: { with: /\A(?=.*[A-Z])(?=.*\d).{6,}\z/, message: "must have at least one uppercase letter, one number, and be at least 6 characters" 
            }, if: -> { password.present? }

  validate :age_is_18_above
  validate :legal_age

  private
  def age_is_18_above
    if birthday.present? && birthday > 18.years.ago.to_date
      errors.add(:birthday, "must be at least 18 years old")
    end
  end

  def legal_age
    if birthday.present? && hire_date.present?
      if birthday > hire_date.years_ago(18)
        errors.add(:hire_date, "must be at least 18 years old to work")
      end
    end
  end
  

end
