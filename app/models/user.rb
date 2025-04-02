class User < ApplicationRecord
  attr_accessor :remove_profile
  has_one_attached :profile_picture
  has_many :cash_adv_requests, foreign_key: "employee_id", primary_key: "employee_id", dependent: :destroy
  has_many :approved_cash_adv_requests, foreign_key: "approver_id", class_name: "CashAdvRequest", dependent: :destroy
  has_many :audit_logs, dependent: :destroy

  
  rolify
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  def self.ransackable_attributes(auth_object = nil)
    super + [ "employee_id", "f_name", "m_name", "l_name", "employee_id", "job_title", "employment_status", "role", "salary" ]
  end

  validates :email, presence: true, uniqueness: { case_sensitive: true }, format: { 
            with: /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]{3,}\z/i, message: "must be a valid email address" }
  
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

  #get the incoming due date and amount
  def self.user_due_cash_advance_amount(user)
    user_cash_adv_requests = CashAdvRequest.where(employee_id: user.employee_id)
  
    user_cash_adv_requests.each do |cash_adv_request|
      # Check if any repayment schedule for this request has a due_date on the 15th or 30th
      due_schedule = cash_adv_request.repayment_schedules.where(
        due_date: [15.days.from_now.beginning_of_month + 14.days, 15.days.from_now.beginning_of_month + 29.days]
      ).first
  
      if due_schedule
        return { amount: due_schedule.amount, cash_adv_request: user_cash_adv_requests }
      else
        return { cash_adv_request: user_cash_adv_requests }
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
    return false unless user.employment_status == 'regular'
    
    eligibility = Eligibility.first
    return false unless user.net_salary.to_f >= eligibility.min_net_salary.to_f
  
    user_cash_adv_requests = CashAdvRequest.where(employee_id: user.employee_id).order(created_at: :desc)
  
    # Check if the user has an existing request with a status that prevent new requests
    user_cash_adv_requests.each do |cash_adv_request|
      case cash_adv_request.status
      when 'pending', 'approved', 'released', 'on-going'
        # Block new requests if the current status is any of the above
        return false
      when 'settled'
        # Check if enough time has passed since the settled request
        if (cash_adv_request.updated_at.to_date - Date.today).to_i < eligibility.req_approve_days
          return false
        else
          return true
        end
      when 'declined'
        # Check if enough time has passed since the declined request
        if (cash_adv_request.updated_at.to_date - Date.today).to_i < eligibility.req_decline_days
          return false
        else
          return true
        end
      end
    end
  
    # If there are no cash advance requests, allow a new request
    user_cash_adv_requests.nil? || user_cash_adv_requests.empty?
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
