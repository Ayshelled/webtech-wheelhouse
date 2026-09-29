module ApplicationHelper
  def field_class(record, attribute, base_class = "form-control")
    record.errors[attribute].any? ? "#{base_class} is-invalid" : base_class
  end

  def field_error_messages(record, attribute)
    safe_join(record.errors.full_messages_for(attribute).map do |message|
      tag.div(message, class: "invalid-feedback d-block")
    end)
  end
end
