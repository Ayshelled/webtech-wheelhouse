class SessionPolicy < ApplicationPolicy
  def destroy?
    user.present?
  end
end
