module Admin
  class UsersController < Admin::ApplicationController
    before_action :set_user, only: [:show, :edit, :update, :update_role]

    def index
      users = User.order(created_at: :desc)
      users = users.where(role: params[:role]) if params[:role].present?
      @pagy, @users = pagy(users)
    end

    def show
    end

    def edit
    end

    def update
      if @user.update(user_params)
        redirect_to admin_user_path(@user), notice: "User updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def update_role
      if @user.update(role: params[:role])
        redirect_to admin_user_path(@user), notice: "Role updated to #{@user.role}."
      else
        redirect_to admin_user_path(@user), alert: "Failed to update role."
      end
    end

    private

    def set_user
      @user = User.find(params[:id])
    end

    def user_params
      params.require(:user).permit(:name, :email, :role, :phone)
    end
  end
end
