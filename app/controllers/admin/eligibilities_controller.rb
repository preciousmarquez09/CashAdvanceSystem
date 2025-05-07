class Admin::EligibilitiesController < ApplicationController
    load_and_authorize_resource
    before_action :authenticate_user!
    
    include RestrictPages
    before_action :authorize_admin!
    
    def edit_eligibility
        @eligibility = Eligibility.first
    end

    def update_eligibility
        @eligibility = Eligibility.first
        
        if @eligibility.update(eligibility_params)
            redirect_to admin_edit_eligibility_path, notice: "Eligibility updated successfully."
        else
            flash[:alert] = "Failed to update eligibility." 
            render :edit_eligibility, status: :unprocessable_entity
        end
    end

    private
    def eligibility_params
        params.require(:eligibility).permit(:percentage_cash_limit, :min_net_salary, :req_decline_days, :req_approve_days, :interest_rate)
    end
end
