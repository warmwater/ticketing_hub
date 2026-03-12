puts "Seeding database..."

# Create Admin
admin = User.find_or_create_by!(email: "admin@tickethub.com") do |u|
  u.name = "Admin User"
  u.password = "password123"
  u.password_confirmation = "password123"
  u.role = :admin
end
puts "  Admin: admin@tickethub.com / password123"

# Create Organizer
organizer = User.find_or_create_by!(email: "organizer@tickethub.com") do |u|
  u.name = "Jane Organizer"
  u.password = "password123"
  u.password_confirmation = "password123"
  u.role = :organizer
end
puts "  Organizer: organizer@tickethub.com / password123"

# Create Attendant
attendant = User.find_or_create_by!(email: "attendant@tickethub.com") do |u|
  u.name = "John Attendant"
  u.password = "password123"
  u.password_confirmation = "password123"
  u.role = :attendant
end
puts "  Attendant: attendant@tickethub.com / password123"

# Create Venues
venues = [
  { name: "Grand Arena", address: "123 Main Street", city: "New York", state: "NY", country: "US", capacity: 20000, description: "A world-class arena for major events." },
  { name: "City Convention Center", address: "456 Oak Avenue", city: "Los Angeles", state: "CA", country: "US", capacity: 5000, description: "Modern convention center with flexible spaces." },
  { name: "The Jazz Club", address: "789 Bourbon Street", city: "New Orleans", state: "LA", country: "US", capacity: 300, description: "Intimate venue for live music." },
  { name: "Tech Hub Auditorium", address: "101 Innovation Drive", city: "San Francisco", state: "CA", country: "US", capacity: 1500, description: "State-of-the-art auditorium for conferences." },
  { name: "Riverside Amphitheater", address: "202 River Road", city: "Austin", state: "TX", country: "US", capacity: 8000, description: "Beautiful outdoor venue by the river." }
].map do |attrs|
  Venue.find_or_create_by!(name: attrs[:name]) do |v|
    v.assign_attributes(attrs.merge(created_by: admin))
  end
end
puts "  Created #{venues.count} venues"

# Create Sections & Seats for The Jazz Club (seated venue)
jazz_club = venues[2]
unless jazz_club.sections.any?
  front = jazz_club.sections.create!(name: "Front Row", section_type: :seated, capacity: 20, position: 0)
  %w[A B].each do |row|
    (1..10).each { |n| front.seats.create!(row_label: row, seat_number: n) }
  end
  front.update!(capacity: front.active_seats.count)

  main_floor = jazz_club.sections.create!(name: "Main Floor", section_type: :seated, capacity: 60, position: 1)
  %w[C D E F G H].each do |row|
    (1..10).each { |n| main_floor.seats.create!(row_label: row, seat_number: n) }
  end
  main_floor.update!(capacity: main_floor.active_seats.count)

  bar_area = jazz_club.sections.create!(name: "Bar Area", section_type: :general_admission, capacity: 50, position: 2)

  jazz_club.update!(capacity: front.active_seats.count + main_floor.active_seats.count + bar_area.capacity)
  puts "  Created sections & seats for The Jazz Club (#{front.active_seats.count + main_floor.active_seats.count} seats + #{bar_area.capacity} GA = #{jazz_club.capacity})"
end

# Create Sections & Seats for Tech Hub Auditorium (seated venue)
tech_hub = venues[3]
unless tech_hub.sections.any?
  orchestra = tech_hub.sections.create!(name: "Orchestra", section_type: :seated, capacity: 200, position: 0)
  ("A".."J").each do |row|
    (1..20).each { |n| orchestra.seats.create!(row_label: row, seat_number: n) }
  end
  orchestra.update!(capacity: orchestra.active_seats.count)

  balcony = tech_hub.sections.create!(name: "Balcony", section_type: :seated, capacity: 100, position: 1)
  ("A".."E").each do |row|
    (1..20).each { |n| balcony.seats.create!(row_label: row, seat_number: n) }
  end
  balcony.update!(capacity: balcony.active_seats.count)

  standing = tech_hub.sections.create!(name: "Standing Room", section_type: :general_admission, capacity: 500, position: 2)

  tech_hub.update!(capacity: orchestra.active_seats.count + balcony.active_seats.count + standing.capacity)
  puts "  Created sections & seats for Tech Hub Auditorium (#{orchestra.active_seats.count + balcony.active_seats.count} seats + #{standing.capacity} GA = #{tech_hub.capacity})"
end

# Create Events
events_data = [
  { name: "Summer Music Festival 2026", description: "The biggest music festival of the summer featuring top artists from around the world. Three days of non-stop entertainment.", venue: venues[0], starts_at: 2.months.from_now, ends_at: 2.months.from_now + 3.days, status: :published, waiting_room_enabled: true, waiting_room_capacity: 50 },
  { name: "Tech Conference 2026", description: "Annual technology conference with keynotes, workshops, and networking. Learn about the latest trends in AI, cloud, and web development.", venue: venues[3], starts_at: 1.month.from_now, ends_at: 1.month.from_now + 2.days, status: :published, seat_selection_mode: :auto_assign },
  { name: "Jazz Night Special", description: "An evening of smooth jazz with renowned musicians. Drinks and appetizers included.", venue: venues[2], starts_at: 3.weeks.from_now, ends_at: 3.weeks.from_now + 4.hours, status: :published, seat_selection_mode: :customer_pick },
  { name: "Startup Pitch Day", description: "Watch innovative startups pitch their ideas to top investors. Networking reception follows.", venue: venues[3], starts_at: 6.weeks.from_now, ends_at: 6.weeks.from_now + 8.hours, status: :draft },
  { name: "River Rock Concert", description: "Rock bands perform at the beautiful riverside amphitheater. Food trucks and craft beer available.", venue: venues[4], starts_at: 3.months.from_now, ends_at: 3.months.from_now + 6.hours, status: :published, waiting_room_enabled: true, waiting_room_capacity: 100 },
  { name: "Comedy Night", description: "Stand-up comedy with the city's funniest performers.", venue: venues[2], starts_at: 2.weeks.from_now, ends_at: 2.weeks.from_now + 3.hours, status: :published }
]

events = events_data.map do |attrs|
  venue = attrs.delete(:venue)
  Event.find_or_create_by!(name: attrs[:name]) do |e|
    e.assign_attributes(attrs.merge(organizer: organizer, venue: venue))
  end
end
puts "  Created #{events.count} events"

# Create Ticket Types
ticket_types_data = {
  "Summer Music Festival 2026" => [
    { name: "General Admission", price: 99.99, quantity: 10000, max_per_order: 4, description: "Standard festival access for all three days." },
    { name: "VIP Pass", price: 249.99, quantity: 2000, max_per_order: 2, description: "VIP area access, premium viewing, complimentary drinks." },
    { name: "Backstage Pass", price: 499.99, quantity: 200, max_per_order: 1, description: "Full backstage access and meet & greet with artists." }
  ],
  "Tech Conference 2026" => [
    { name: "Orchestra Seat", price: 199.00, quantity: 200, max_per_order: 5, description: "Orchestra level seating with great views.", section_name: "Orchestra" },
    { name: "Balcony Seat", price: 149.00, quantity: 100, max_per_order: 5, description: "Balcony level seating.", section_name: "Balcony" },
    { name: "Standing Room", price: 49.00, quantity: 500, max_per_order: 4, description: "Standing room only — general admission.", section_name: "Standing Room" }
  ],
  "Jazz Night Special" => [
    { name: "Front Row Seat", price: 85.00, quantity: 20, max_per_order: 2, description: "Premium front row seating near the stage.", section_name: "Front Row" },
    { name: "Main Floor Seat", price: 55.00, quantity: 60, max_per_order: 4, description: "Main floor seating with great acoustics.", section_name: "Main Floor" },
    { name: "Bar Area (Standing)", price: 35.00, quantity: 50, max_per_order: 4, description: "Standing area near the bar with drinks available.", section_name: "Bar Area" }
  ],
  "River Rock Concert" => [
    { name: "General Standing", price: 55.00, quantity: 5000, max_per_order: 6, description: "General admission standing area." },
    { name: "Reserved Seating", price: 95.00, quantity: 2000, max_per_order: 4, description: "Reserved seating with great views." },
    { name: "VIP Lounge", price: 175.00, quantity: 500, max_per_order: 2, description: "Exclusive lounge with open bar and catering." }
  ],
  "Comedy Night" => [
    { name: "General Admission", price: 25.00, quantity: 250, max_per_order: 6, description: "Open seating." },
    { name: "VIP Table", price: 60.00, quantity: 40, max_per_order: 4, description: "Reserved table near the stage." }
  ],
  "Startup Pitch Day" => [
    { name: "Observer Pass", price: 0.00, quantity: 1000, max_per_order: 2, description: "Free admission to watch the pitches." },
    { name: "Investor Pass", price: 150.00, quantity: 100, max_per_order: 1, description: "Premium networking and pitch book access." }
  ]
}

ticket_count = 0
ticket_types_data.each do |event_name, types|
  event = Event.find_by(name: event_name)
  next unless event

  types.each do |attrs|
    section_name = attrs.delete(:section_name)
    section = section_name ? event.venue.sections.find_by(name: section_name) : nil

    TicketType.find_or_create_by!(event: event, name: attrs[:name]) do |tt|
      tt.assign_attributes(attrs)
      tt.section = section if section
    end
    ticket_count += 1
  end
end
puts "  Created #{ticket_count} ticket types"

puts "\nSeeding complete!"
puts "Login credentials:"
puts "  Admin:     admin@tickethub.com / password123"
puts "  Organizer: organizer@tickethub.com / password123"
puts "  Attendant: attendant@tickethub.com / password123"
