#!/usr/bin/env ruby

# Factoryテストスクリプト
# Docker環境での実行を想定

require 'bundler/setup'
require 'rails'
require 'active_record'

# Rails環境の設定
ENV['RAILS_ENV'] = 'test'
require_relative 'config/environment'

require 'factory_bot'
require 'faker'

# Factoryファイルを読み込み
Dir[Rails.root.join('spec/factories/**/*.rb')].each { |f| require f }

FactoryBot.find_definitions

puts "Testing Factories..."

begin
  # User Factoryテスト
  puts "\n1. Testing User Factory..."
  user = FactoryBot.create(:user, :patient)
  puts "✓ User created: #{user.name} (ID: #{user.user_id})"
  puts "✓ User has role: #{user.current_hospital_role&.role&.name}"
  puts "✓ User has hospital: #{user.current_hospital_role&.hospital&.name}"

  # Role Factoryテスト
  puts "\n2. Testing Role Factory..."
  patient_role = FactoryBot.create(:role, :patient)
  doctor_role = FactoryBot.create(:role, :doctor)
  puts "✓ Patient role: #{patient_role.name}"
  puts "✓ Doctor role: #{doctor_role.name}"

  # Hospital Factoryテスト
  puts "\n3. Testing Hospital Factory..."
  hospital = FactoryBot.create(:hospital)
  puts "✓ Hospital created: #{hospital.name}"

  # BloodPressureRecord Factoryテスト
  puts "\n4. Testing BloodPressureRecord Factory..."
  record = FactoryBot.create(:blood_pressure_record, user: user)
  puts "✓ Blood pressure record created: #{record.systolic_pressure}/#{record.diastolic_pressure}"

  # UserHospitalRole Factoryテスト
  puts "\n5. Testing UserHospitalRole Factory..."
  uhr = FactoryBot.create(:user_hospital_role)
  puts "✓ UserHospitalRole created"

  puts "\n✅ All Factory tests passed!"

rescue => e
  puts "\n❌ Factory test failed: #{e.message}"
  puts e.backtrace.join("\n")
end
