# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)
User.create!(name:  "Example User",
             email: "example@railstutorial.org",
             password:              "foobar",
             password_confirmation: "foobar",
             admin: true,
             activated: true,
             activated_at: Time.zone.now)

25.times do |n|
  name  = Faker::Name.name
  email = "example-#{n+1}@railstutorial.org"
  password = "password"
  role = "Freelancer"
  User.create!(name:  name,
               email: email,
               password:              password,
               password_confirmation: password,
               role: role,
               activated: true,
               activated_at: Time.zone.now)
end

25.times do |n|
  name  = Faker::Name.name
  email = "example-#{n+26}@railstutorial.org"
  password = "password"
  role = "Client"
  User.create!(name:  name,
               email: email,
               password:              password,
               password_confirmation: password,
               role: role,
               activated: true,
               activated_at: Time.zone.now)
end

Category.where(
        name: "Web Development"
        ).first_or_create(
          name: "Web Development"
         )
Category.where(
        name: "Design"
        ).first_or_create(
          name: "Design"
         )
Category.where(
        name: "Finance"
        ).first_or_create(
          name: "Finance"
         ) 
Category.where(
        name: "Engineering"
        ).first_or_create(
          name: "Engineering"
         )
Category.where(
        name: "Sales"
        ).first_or_create(
          name: "Sales"
         )         
Category.where(
        name: "Administrative"
        ).first_or_create(
          name: "Administrative"
         ) 

location = [
  "New Delhi",
  "Mumbai",
  "Kolkata",
  "Pune",
  "Chennai",
  "Bengaluru",
  "Mysore"
]

User.where(role: "Client").each do |client|
  50.times do
    Gig.create(
               name: Faker::Job.title,
               description: Faker::Lorem.paragraph(sentence_count: 5),
               budget: rand(200..10000),
               location: location.sample,
               user_id: client.id,
               category_id: rand(1..6)
               )

  end
end