class TicketTypePolicy < ApplicationPolicy
  def create?
    user.admin? || user.organizer?
  end

  def update?
    user.admin? || record.event.organizer == user
  end

  def destroy?
    update?
  end
end
