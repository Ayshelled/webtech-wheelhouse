class BikePolicy < ApplicationPolicy
  def index?
    can_manage_bikes?
  end

  def show?
    can_manage_bikes?
  end

  def new?
    can_manage_bikes?
  end

  def create?
    can_manage_bikes?
  end

  def edit?
    can_manage_bikes?
  end

  def update?
    can_manage_bikes?
  end

  def destroy?
    user&.owner? || false
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      user&.owner? || user&.counter? ? scope.all : scope.none
    end
  end

  private

  def can_manage_bikes?
    user&.owner? || user&.counter? || false
  end
end
