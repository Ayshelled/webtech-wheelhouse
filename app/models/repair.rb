class Repair < ApplicationRecord
    belongs_to :bike
    belongs_to :intake_staff, class_name: "Staff"
    belongs_to :assigned_staff, class_name: "Staff", optional: true
    has_many :repair_line_items, -> { by_repair }, dependent: :destroy
    has_many :services, through: :repair_line_items, source: :service_catalog_item, dependent: :restrict_with_error
    has_many_attached :photos, dependent: :purge do |photo|
        photo.variant :thumbnail, resize_to_fill: [ 80, 60 ]
        photo.variant :large, resize_to_limit: [ 1200, 900 ]
    end
    has_rich_text :diagnosis

    accepts_nested_attributes_for :repair_line_items, allow_destroy: true,
        reject_if: ->(attributes) { attributes["service_catalog_item_id"].blank? }

    enum :status, {
        tagged: "Tagged",
        diagnosing: "Diagnosing",
        awaiting_approval: "Awaiting Approval",
        approved: "Approved",
        in_progress: "In Progress",
        ready_for_pickup: "Ready for Pickup",
        declined: "Declined",
        picked_up: "Picked Up"
    }

    scope :by_promised_on, -> { order(:promised_on, :id) }
    scope :open, -> { where(handed_back_at: nil) }
    scope :overdue, -> { open.where("promised_on < ?", Date.current) }

    validates :bike, :intake_staff, :promised_on, :status, presence: true

    validate :photos_are_valid
    validate :dates_are_consistent
    validate :lifecycle_data_is_consistent

    def overdue?
        handed_back_at.nil? && promised_on < Date.current
    end

    def total
        repair_line_items.sum(&:price_charged)
    end

    private

    def photos_are_valid
        attachables = attachment_changes["photos"]&.attachables || []
        attachables.each do |photo|
            details = photo.is_a?(Hash) ? photo : {}
            file = details.fetch(:io, photo)
            filename = details[:filename] ||
                (file.respond_to?(:original_filename) ? file.original_filename : file.filename.to_s)
            declared_type = details[:content_type] || (file.content_type if file.respond_to?(:content_type))
            source = file.respond_to?(:tempfile) ? file.tempfile : file
            content_type = if source.respond_to?(:read)
                Marcel::MimeType.for(source, name: filename, declared_type: declared_type)
            else
                declared_type
            end
            size = file.respond_to?(:size) ? file.size : file.byte_size

            unless %w[image/jpeg image/png].include?(content_type)
                errors.add(:photos, "#{filename} must be a JPEG or PNG image.")
            end

            if size > 5.megabytes
                errors.add(:photos, "#{filename} must be no larger than 5 MB.")
            end
        end
    end

    def dates_are_consistent
        if handed_back_at.present? && created_at.present? && handed_back_at < created_at
            errors.add(:handed_back_at, "cannot be before the repair came in.")
        end

        if promised_on.present? && created_at.present? && promised_on < created_at.to_date
            errors.add(:promised_on, "cannot be before the repair came in.")
        end
    end

    def lifecycle_data_is_consistent
        if handed_back_at.blank? && picked_up?
            errors.add(:handed_back_at, "must be recorded for a picked-up repair.")
        elsif handed_back_at.present? && !picked_up?
            errors.add(:handed_back_at, "must be blank until the repair is picked up.")
        end

        if (approved? || in_progress? || ready_for_pickup? || declined? || picked_up?) && customer_approved.nil?
            errors.add(:customer_approved, "must be recorded after the customer's decision.")
        end
    end
end
