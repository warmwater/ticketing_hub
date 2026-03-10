class OrderPolicy < ApplicationPolicy
  def show?
    user.admin? || record.user == user || record.event.organizer == user
  end

  def create?
    user.present?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user.admin?
        scope.all
      else
        scope.where(user: user)
      end
    end
  end
end
