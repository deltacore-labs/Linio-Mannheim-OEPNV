#!/usr/bin/env ruby
# Fügt ein Unit-Test-Target für LinioWatch zum Xcode-Projekt hinzu
#
# Ausführung: ruby add_watch_test_target.rb

require 'xcodeproj'

project_path = 'Linio.xcodeproj'
project = Xcodeproj::Project.open(project_path)

if project.targets.any? { |t| t.name == 'LinioWatchTests' }
  puts "✅ LinioWatchTests Target existiert bereits"
  exit 0
end

watch_target = project.targets.find { |t| t.name == 'LinioWatch' }
unless watch_target
  puts "❌ Haupttarget 'LinioWatch' nicht gefunden"
  exit 1
end

test_target = project.new_target(:unit_test_bundle, 'LinioWatchTests', :watchos, '7.0')

test_target.build_configurations.each do |config|
  config.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = 'Stefan.Mannheim-Transportation.LinioWatchTests'
  config.build_settings['INFOPLIST_FILE'] = 'LinioWatchTests/Info.plist'
  config.build_settings['SWIFT_VERSION'] = '5.9'
  config.build_settings['TEST_HOST'] = '$(BUILT_PRODUCTS_DIR)/LinioWatch.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/LinioWatch'
  config.build_settings['BUNDLE_LOADER'] = '$(TEST_HOST)'
  config.build_settings['CODE_SIGN_STYLE'] = 'Automatic'
  config.build_settings['DEVELOPMENT_TEAM'] = 'A4HCRKN53K'
end

test_target.add_dependency(watch_target)

tests_group = project.main_group.new_group('LinioWatchTests', 'LinioWatchTests')
tests_group.set_source_tree('<group>')

test_files = Dir.glob('LinioWatchTests/*.swift')
test_files.each do |file_path|
  file_name = File.basename(file_path)
  file_ref = tests_group.new_file(file_name)
  test_target.source_build_phase.add_file_reference(file_ref)
end

info_plist_ref = tests_group.new_file('Info.plist')

project.save

puts "✅ LinioWatchTests Target erfolgreich hinzugefügt!"
puts "   #{test_files.count} Test-Dateien hinzugefügt."
