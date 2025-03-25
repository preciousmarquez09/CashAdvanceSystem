class EligibilitiesController < ApplicationController
    load_and_authorize_resource
    
    def edit_eligibility
        @eligibility = Eligibility.first
    end

    def update_eligibility
        @eligibility = Eligibility.first
        
        if params[:eligibility][:percentage_cash_limit].present?
            #@eligibility.percentage_cash_limit = params[:eligibility][:percentage_cash_limit].to_f / 100
            Rails.logger.info "Update failed: #{params[:eligibility][:percentage_cash_limit].to_f / 100}"

        end

        if params[:eligibility][:interest_rate].present?
            #@eligibility.interest_rate = params[:eligibility][:interest_rate].to_f / 100
            Rails.logger.info "Update failed: #{params[:eligibility][:interest_rate].to_f / 100}"

        end
        
        if @eligibility.update(eligibility_params)

            redirect_to edit_eligibility_path, notice: "Eligibility updated successfully."
        else
            Rails.logger.error "Update failed: #{@eligibility.errors.full_messages.join(', ')}"
            render :edit_eligibility, status: :unprocessable_entity
        end
    end

    private
    def eligibility_params
        params.require(:eligibility).permit(:percentage_cash_limit, :min_net_salary, :req_decline_days, :req_approve_days, :interest_rate)
    end
end
