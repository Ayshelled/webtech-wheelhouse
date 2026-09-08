# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

services = {
  "Basic tune-up" => 85.00,
  "Full tune-up" => 150.00,
  "Wheel truing" => 45.00,
  "Brake bleed" => 60.00,
  "Chain replacement" => 35.00,
  "Brake pad replacement" => 40.00,
  "Tyre replacement" => 55.00,
  "Inner tube replacement" => 18.00,
  "Gear adjustment" => 35.00,
  "Headset adjustment" => 30.00,
  "Bottom bracket service" => 95.00,
  "Spoke replacement" => 25.00,
  "Full bike wash" => 30.00,
  "Handlebar tape wrap" => 35.00,
  "Pedal replacement" => 45.00,
  "Puncture repair" => 20.00,
  "Cable replacement" => 30.00,
  "Tubeless sealant refresh" => 25.00,
  "Bike assembly" => 120.00,
  "Safety inspection" => 25.00
}

service_records = {}
services.each do |name, price|
  service = ServiceCatalogItem.find_or_initialize_by(name: name)
  service.price = price
  service.save!
  service_records[name] = service
end

staff_records = {}
[
  ["Maya Singh", "Mechanic"],
  ["Tom Bennett", "Mechanic"],
  ["Lucia Moretti", "Mechanic"],
  ["Evan Brooks", "Counter staff"]
].each do |name, role|
  staff = Staff.find_or_initialize_by(name: name)
  staff.role = role
  staff.save!
  staff_records[name] = staff
end

customer_records = {}
[
  ["Amelia Hart", "07700 900101"],
  ["Noah Wilson", "07700 900102"],
  ["Priya Shah", "07700 900103"],
  ["Oliver Brown", "07700 900104"],
  ["Sofia Martin", "07700 900105"],
  ["James Taylor", "07700 900106"],
  ["Grace Evans", "07700 900107"],
  ["Daniel Clarke", "07700 900108"],
  ["Ella Robinson", "07700 900109"],
  ["Henry Lewis", "07700 900110"]
].each do |name, phone|
  customer = Customer.find_or_initialize_by(name: name)
  customer.phone = phone
  customer.save!
  customer_records[name] = customer
end

bike_records = {}
[
  ["Amelia Hart", "Trek", "Marlin 7", "TRK-M7-001"],
  ["Amelia Hart", "Trek", "Marlin 7", "TRK-M7-002"],
  ["Noah Wilson", "Specialized", "Sirrus 2.0", "SP-S2-001"],
  ["Priya Shah", "Giant", "Contend AR 3", "GI-CAR3-001"],
  ["Oliver Brown", "Cannondale", "Quick 4", "CA-Q4-001"],
  ["Sofia Martin", "Brompton", "C Line", "BR-CL-001"],
  ["James Taylor", "Cube", "Aim Pro", "CU-AP-001"],
  ["Grace Evans", "Scott", "Speedster 40", "SC-S40-001"],
  ["Daniel Clarke", "Raleigh", "Strada", "RA-ST-001"],
  ["Ella Robinson", "Boardman", "HYB 8.6", "BO-H86-001"],
  ["Henry Lewis", "Merida", "Big Nine 20", "ME-BN20-001"],
  ["Henry Lewis", "Kona", "Dew Plus", "KO-DP-001"]
].each do |customer_name, make, model, serial_number|
  bike = Bike.find_or_initialize_by(serial_number: serial_number)
  bike.customer_id = customer_records.fetch(customer_name).id
  bike.make = make
  bike.model = model
  bike.save!
  bike_records[serial_number] = bike
end

today = Date.current
repairs = [
  ["TRK-M7-001", "Tagged", nil, nil, nil, 0, ["Safety inspection"]],
  ["TRK-M7-002", "Diagnosing", nil, nil, nil, -1, ["Basic tune-up"]],
  ["SP-S2-001", "Awaiting Approval", nil, nil, nil, -2, ["Brake pad replacement", "Cable replacement"]],
  ["GI-CAR3-001", "Approved", true, today - 3.hours, today - 3.days, -4, ["Full tune-up", "Chain replacement"]],
  ["CA-Q4-001", "In Progress", true, today - 1.day, today - 5.days, -2, ["Wheel truing"]],
  ["BR-CL-001", "Ready for Pickup", true, today - 2.days, today - 6.days, -7, ["Gear adjustment", "Full bike wash"]],
  ["CU-AP-001", "Picked Up", true, today - 8.days, today - 12.days, -15, ["Bottom bracket service"]],
  ["SC-S40-001", "Declined", false, nil, today - 4.days, -5, ["Tubeless sealant refresh"]],
  ["RA-ST-001", "In Progress", true, today - 2.days, today - 3.days, -1, ["Puncture repair", "Inner tube replacement"]],
  ["BO-H86-001", "Picked Up", true, today - 10.days, today - 14.days, -20, ["Full tune-up", "Handlebar tape wrap"]],
  ["ME-BN20-001", "Ready for Pickup", true, today - 1.day, today - 3.days, -3, ["Brake bleed"]],
  ["KO-DP-001", "Tagged", nil, nil, nil, 1, ["Safety inspection"]],
  ["TRK-M7-001", "Diagnosing", nil, nil, nil, 2, ["Tyre replacement"]],
  ["SP-S2-001", "Approved", true, today - 1.hour, today - 2.days, -1, ["Gear adjustment", "Cable replacement"]],
  ["GI-CAR3-001", "Picked Up", true, today - 20.days, today - 25.days, -30, ["Basic tune-up", "Spoke replacement"]]
]

repairs.each do |serial, status, approved, approved_at, quoted_at, promised_offset, service_names|
  repair = Repair.find_or_initialize_by(
    bike_id: bike_records.fetch(serial).id,
    promised_on: today + promised_offset
  )

  repair.intake_staff_id = staff_records.fetch("Evan Brooks").id
  repair.assigned_staff_id = staff_records.fetch("Maya Singh").id unless status == "Tagged"
  repair.status = status
  repair.customer_approved = approved
  repair.approved_at = approved_at
  repair.quoted_at = quoted_at
  repair.handed_back_at = status == "Picked Up" ? today - 1.day : nil
  repair.save!

  service_names.each_with_index do |service_name, index|
    line_item = RepairLineItem.find_or_initialize_by(
      repair_id: repair.id,
      service_catalog_item_id: service_records.fetch(service_name).id
    )
    line_item.price_charged =
      if index.zero? && status == "Picked Up"
        service_records.fetch(service_name).price * 0.90
      else
        service_records.fetch(service_name).price
      end
    line_item.save!
  end
end
