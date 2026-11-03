class RepairPolicy < ApplicationPolicy
  def index?
    user.present?
  end

  def show?
    user&.owner? || user&.counter? || own_repair? || false
  end

  def new?
    user&.owner? || user&.counter? || false
  end

  def create?
    user&.owner? || user&.counter? || false
  end

  def edit?
    owner? || editable_by_counter? || editable_by_mechanic?
  end

  def update?
    edit?
  end

  def destroy?
    owner?
  end

  def remove_photo?
    owner? || editable_by_counter?
  end

  def permitted_attributes
    return [] unless user&.owner? || user&.counter? || editable_by_mechanic?

    return mechanic_attributes if user&.mechanic?

    [
      :bike_id, :intake_staff_id, :assigned_staff_id, :promised_on, :status,
      :customer_approved, :approved_at, :quoted_at, :handed_back_at,
      :diagnosis, { photos: [],
        repair_line_items_attributes: [ [ :id, :service_catalog_item_id, :price_charged, :_destroy ] ] }
    ]
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.all if user&.owner? || user&.counter?
      return scope.where(assigned_staff_id: user.staff_id) if user&.mechanic? && user.staff_id.present?

      scope.none
    end
  end

  private

  def owner?
    user&.owner? || false
  end

  def editable_by_counter?
    user&.counter? && record.handed_back_at.nil?
  end

  def editable_by_mechanic?
    user&.mechanic? && own_repair? && record.handed_back_at.nil?
  end

  def own_repair?
    user&.mechanic? && user.staff_id.present? && record.assigned_staff_id == user.staff_id
  end

  def mechanic_attributes
    [ :status, :diagnosis, { photos: [] } ]
  end
end
