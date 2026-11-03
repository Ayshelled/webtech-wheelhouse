class StaffPolicy < ApplicationPolicy
  def index?
    user.present?
  end

  def show?
    user.present?
  end

  def new?
    user&.owner? || false
  end

  def create?
    user&.owner? || false
  end

  def edit?
    user&.owner? || false
  end

  def update?
    user&.owner? || false
  end

  def destroy?
    user&.owner? || false
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      user.present? ? scope.all : scope.none
    end
  end
end
