class ServiceCatalogItemPolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    true
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
      scope.all
    end
  end
end
