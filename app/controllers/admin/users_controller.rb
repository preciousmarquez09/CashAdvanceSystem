class Admin::UsersController < ApplicationController

    def index
        @users = User.includes(:roles)
    end

end
