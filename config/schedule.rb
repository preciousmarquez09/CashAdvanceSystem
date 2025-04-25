# Use this file to easily define all of your cron jobs.
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron

# Example:
#
# set :output, "/path/to/my/cron_log.log"
#
# every 2.hours do
#   command "/usr/bin/some_great_command"
#   runner "MyModel.some_method"
#   rake "some:great:rake:task"
# end
#
# every 4.days do
#   runner "AnotherModel.prune_old_records"
# end

# Learn more: http://github.com/javan/whenever

# whenever --update-cron

#change every 1.minute for testing
#every 1.minute do

#update repayment schedule status
#every */1 - (every minute) , * - (every hour), 15,30 - (every 15th and 30th day), * * - (every month and every day of the week)

#update cash advance status
#every 1.minute do
 #   command "cd /home/precious/code/cash_advance && RAILS_ENV=development bundle exec rails runner 'RepaymentSchedule.update_cashadvreq_status_to_ongoing' >> /home/precious/code/cash_advance/log/cron.log 2>&1"
#end

#every */1 * 15,30 * * do
    #use command since it needs the default environment of runner is production
 #   command "cd /home/precious/code/cash_advance && RAILS_ENV=development bundle exec rails runner 'RepaymentSchedule.update_due_statuses' >> /home/precious/code/cash_advance/log/cron.log 2>&1"
#end
#every 1.minute do
 #   command "cd /home/precious/code/cash_advance && RAILS_ENV=development bundle exec rails runner 'RepaymentSchedule.update_cashadvreq_status_to_settled' >> /home/precious/code/cash_advance/log/cron.log 2>&1"
#end

every 1.minute do
  command <<-CMD
    cd /home/precious/code/cash_advance && RAILS_ENV=development bundle exec rails runner 'GeneratePayroll.perform' >> /home/precious/code/cash_advance/log/cron.log 2>&1 && \
    cd /home/precious/code/cash_advance && RAILS_ENV=development bundle exec rails runner 'RepaymentSchedule.update_cashadvreq_status_to_ongoing' >> /home/precious/code/cash_advance/log/cron.log 2>&1 && \
    cd /home/precious/code/cash_advance && RAILS_ENV=development bundle exec rails runner 'RepaymentSchedule.update_due_statuses' >> /home/precious/code/cash_advance/log/cron.log 2>&1 && \
    cd /home/precious/code/cash_advance && RAILS_ENV=development bundle exec rails runner 'RepaymentSchedule.update_cashadvreq_status_to_settled' >> /home/precious/code/cash_advance/log/cron.log 2>&1
  CMD
  
end
  
  
