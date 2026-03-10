class EventPolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    true
  end

  def create?
    user.organizer? || user.admin?
  end

  def update?
    user.admin? || record.organizer == user
  end

  def destroy?
    user.admin? || record.organizer == user
  end

  def publish?
    update?
  end

  def cancel?
    update?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user.admin?
        scope.all
      elsif user.organizer?
        scope.where(organizer: user)
      else
        scope.published
      end
    end
  end
end
