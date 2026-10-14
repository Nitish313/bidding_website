# Seed data for development. Safe to run more than once: `bin/rails db:seed`.

# Admin account. Set SEED_ADMIN_EMAIL and SEED_ADMIN_PASSWORD to choose the
# credentials; without a password, a random one is generated and printed once.
admin_email = ENV["SEED_ADMIN_EMAIL"].presence || "admin@example.com"
unless User.exists?(email: admin_email.downcase)
  chosen_password = ENV["SEED_ADMIN_PASSWORD"].presence
  admin_password = chosen_password || SecureRandom.alphanumeric(20)
  User.create!(name: "Admin", email: admin_email,
               password: admin_password, password_confirmation: admin_password,
               admin: true, activated: true, activated_at: Time.zone.now)
  if chosen_password
    puts "Created admin #{admin_email} with the password from SEED_ADMIN_PASSWORD"
  else
    puts "Created admin #{admin_email} with password #{admin_password}"
  end
end

["Web Development", "Web Design", "Content Writer", "Project Management", "SEO service", "Marketing/Sales"].each do |name|
  Category.find_or_create_by!(name: name)
end
