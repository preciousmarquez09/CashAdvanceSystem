# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)
require 'faker'

10.times do
  password = Faker::Internet.password(min_length: 6, mix_case: true, special_characters: false) + "1A"  # Ensure valid password

  birthday = Faker::Date.birthday(min_age: 18, max_age: 65)
  hire_date = Faker::Date.between(from: birthday + 18.years, to: Date.today) # Ensure legal hiring age

  job_title = Faker::Job.title.gsub(/[^a-zA-Z]/, '')  # Remove non-letter characters, no spaces

  begin
    User.create!(
      email: Faker::Internet.unique.email,
      password: password,
      password_confirmation: password,
      employee_id: Faker::Number.unique.number(digits: 6),
      f_name: Faker::Name.first_name.gsub(/[^a-zA-Z]/, ''),  # Only letters
      m_name: Faker::Name.middle_name.gsub(/[^a-zA-Z]/, ''),  # Only letters
      l_name: Faker::Name.last_name.gsub(/[^a-zA-Z]/, ''),  # Only letters
      birthday: birthday,
      civil_status: %w[Single Married Widow].sample,
      gender: %w[male female].sample,
      job_title: job_title,
      employment_status: %w[regular probationary].sample,
      hire_date: hire_date,
      salary: rand(30_000..100_000).to_s, # Convert to string for length validation
      role: %w[Employee Finance Admin].sample
    )
  rescue ActiveRecord::RecordInvalid => e
    puts "❌ Error creating user: #{e.record.errors.full_messages.join(', ')}"
  end
end

puts "✅ Successfully created 10 fake users!"



