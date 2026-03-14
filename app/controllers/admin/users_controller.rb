module Admin
  class UsersController < Admin::ApplicationController
    before_action :set_user, only: [ :show, :edit, :update, :update_role ]

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
        redirect_to admin_user_path(@user), notice: t("flash.admin.user_updated")
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def update_role
      if @user.update(role: params[:role])
        redirect_to admin_user_path(@user), notice: t("flash.admin.role_updated", role: @user.role)
      else
        redirect_to admin_user_path(@user), alert: t("flash.admin.role_update_failed")
      end
    end

    private

    def set_user
      @user = User.find(params[:id])
    end

    def user_params
      params.require(:user).permit(:name, :email, :phone)
    end
  end
end
