# uncomment if u want to run the generate payroll run on server start

# # This will run when the server starts
# Rails.application.config.after_initialize do
#     # Ensure that the server only runs this once, not every request
#     if Rails.env.development? # You can change this to match the environment you need
#       GeneratePayroll.perform
#     end
#   end
  