# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)
User.create!(name:  "Admin",
             email: "admin@rails.org",
             password:              "password",
             password_confirmation: "password",
             admin: true,
             activated: true,
             activated_at: Time.zone.now)

Category.where(name: "Web Development").first_or_create(name: "Web Development")
Category.where(name: "Web Design").first_or_create(name: "Web Design")
Category.where(name: "Content Writer").first_or_create(name: "Content Writer") 
Category.where(name: "Project Management").first_or_create(name: "Project Management")
Category.where(name: "SEO service").first_or_create(name: "SEO service")         
Category.where(name: "Marketing/Sales").first_or_create(name: "Marketing/Sales") 

Skill.where(name: 'Android Developer').first_or_create(name: 'Android Developer')
Skill.where(name: 'Java Developer').first_or_create(name: 'Java Developer')
Skill.where(name: 'RoR Developer').first_or_create(name: 'RoR Developer')
Skill.where(name: 'Graphic Designer').first_or_create(name: 'Graphic Designer')
Skill.where(name: 'HTML/CSS Developer').first_or_create(name: 'HTML/CSS Developer')
Skill.where(name: 'System Admin').first_or_create(name: 'System Admin')
Skill.where(name: 'Data Scientist').first_or_create(name: 'Data Scientist')
Skill.where(name: 'Technical Writer').first_or_create(name: 'Technical Writer')