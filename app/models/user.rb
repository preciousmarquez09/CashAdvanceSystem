class User < ApplicationRecord
  attr_accessor :remove_profile
  has_one_attached :profile_picture
  has_many :cash_adv_requests, foreign_key: "employee_id", primary_key: "employee_id", dependent: :destroy
  has_many :approved_cash_adv_requests, foreign_key: "approver_id", class_name: "CashAdvRequest", dependent: :destroy
  has_many :audit_logs, dependent: :destroy
  has_many :notifications, as: :recipient, dependent: :destroy
  has_many :payrolls, foreign_key: 'user_id', dependent: :destroy


  rolify
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  def self.ransackable_attributes(auth_object = nil)
    super + [ "employee_id", "f_name", "m_name", "l_name", "employee_id", "job_title", "employment_status", "role", "salary" ]
  end

  validates :email, presence: true, uniqueness: { case_sensitive: true }, format: {
  with: /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]{2,}\z/i, message: "must be a valid email address" }

  
  validates :employment_status, :gender, presence: true
  validates :f_name, presence: true, length: { minimum: 2 }, if: -> { f_name.present? }, format: { with: /\A[a-zA-Z\s]+\z/, message: "only allows letters" }
  validates :m_name, presence: true, length: { minimum: 2 }, if: -> { m_name.present? }, format: { with: /\A[a-zA-Z\s]+\z/, message: "only allows letters" }
  validates :l_name, presence: true, length: { minimum: 2 }, if: -> { l_name.present? }, format: { with: /\A[a-zA-Z\s]+\z/, message: "only allows letters" }
  validates :job_title, presence: true, length: { minimum: 2 }, if: -> { job_title.present? }, format: { with: /\A[a-zA-Z\s]+\z/, message: "only allows letters" }
  validates :employee_id, presence: true, numericality: { only_integer: true }, format: { with: /\A\d+\z/, message: "only allows numbers" }
  validates :employee_id, uniqueness: true
  validates :salary, presence: true, length: { minimum: 4 }, numericality: { only_integer: true }, format: { with: /\A\d+\z/, message: "only allows numbers" }

  validates :password, format: { with: /\A(?=.*[A-Z])(?=.*\d).{6,}\z/, message: "must have at least one uppercase letter, one number, and be at least 6 characters" 
            }, if: -> { password.present? }

  validate :age_is_18_above
  validate :legal_age
  validates :salary, numericality: { greater_than_or_equal_to: 0 }

  #get the incoming due date and amount
  def self.user_due_cash_advance_amount(user)
    user_cash_adv_requests = CashAdvRequest.where(employee_id: user.employee_id)
  
    user_cash_adv_requests.each do |cash_adv_request|
      fifteenth = Date.current.change(day: 15).all_day
      thirtieth = Date.current.change(day: 30).all_day
  
      due_schedule = cash_adv_request.repayment_schedules.where(due_date: fifteenth)
        .or(cash_adv_request.repayment_schedules.where(due_date: thirtieth)).first
  
      if due_schedule
        return { amount: due_schedule.amount, cash_adv_request: user_cash_adv_requests }
      end
    end
    nil
  end
  
  
  def self.gov_contribution(salary)
    sss = salary < 20000 ? 500 : 1000
    pagibig = 200
    philhealth = (salary * 0.05) / 2

    { sss: sss, pagibig: pagibig, philhealth: philhealth }
  end

  def self.can_request_cashadv(user)
    unless user
      Rails.logger.debug "User not found"
      return false
    end
  
    unless user.employment_status == 'regular'
      Rails.logger.debug "User is not regular"
      return false
    end
  
    eligibility = Eligibility.first
    unless user.net_salary.to_f >= eligibility.min_net_salary.to_f
      Rails.logger.debug "User's net salary is too low"
      return false
    end
  
    user_cash_adv_requests = CashAdvRequest.where(employee_id: user.employee_id).order(created_at: :desc)
  
    user_cash_adv_requests.each do |cash_adv_request|
      case cash_adv_request.status
      when 'pending', 'approved', 'released', 'on-going'
        Rails.logger.debug "Request status #{cash_adv_request.status} prevents new request"
        return false
      when 'settled'
          days_since_settled = (cash_adv_request.updated_at.to_date - Date.today).to_i
          days_since_settled = [days_since_settled, 0].max  # Ensure non-negative days
        if  days_since_settled < eligibility.req_approve_days
          Rails.logger.debug "Request settled too recently to allow new request"
          return false
        else
          return true
        end
      when 'declined'
        days_since_decline = (cash_adv_request.updated_at.to_date - Date.today).to_i
        days_since_decline = [days_since_decline, 0].max  # Ensure non-negative days
        if days_since_decline < eligibility.req_decline_days
          Rails.logger.info days_since_decline
          Rails.logger.debug "Request declined too recently to allow new request"
          return false
        else
          return true
        end
      end
    end

    if user_cash_adv_requests.nil? || user_cash_adv_requests.empty?
      Rails.logger.debug "No previous cash advance requests, allowing new one"
      return true
    end
  end
  

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
