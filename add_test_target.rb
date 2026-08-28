#!/usr/bin/env ruby
# Fügt ein Unit-Test-Target zum Xcode-Projekt hinzu
#
# Ausführung: gem install xcodeproj && ruby add_test_target.rb
#

require 'xcodeproj'

project_path = 'Linio.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Prüfe ob Tests-Target bereits existiert
if project.targets.any? { |t| t.name == 'LinioTests' }
  puts "✅ LinioTests Target existiert bereits"
  exit 0
end

# Finde das Haupttarget
main_target = project.targets.find { |t| t.name == 'Linio' }
unless main_target
  puts "❌ Haupttarget 'Linio' nicht gefunden"
  exit 1
end

# Erstelle Test-Target
test_target = project.new_target(:unit_test_bundle, 'LinioTests', :ios, '18.0')

# Setze Bundle-Identifier und andere Einstellungen
test_target.build_configurations.each do |config|
  config.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = 'Stefan.Mannheim-Transportation.LinioTests'
  config.build_settings['INFOPLIST_FILE'] = 'LinioTests/Info.plist'
  config.build_settings['SWIFT_VERSION'] = '5.9'
  config.build_settings['TEST_HOST'] = '$(BUILT_PRODUCTS_DIR)/Linio.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/Linio'
  config.build_settings['BUNDLE_LOADER'] = '$(TEST_HOST)'
  config.build_settings['CODE_SIGN_STYLE'] = 'Automatic'
  config.build_settings['DEVELOPMENT_TEAM'] = 'A4HCRKN53K'
end

# Füge Abhängigkeit zum Haupttarget hinzu
test_target.add_dependency(main_target)

# Erstelle Gruppe für Tests
tests_group = project.main_group.find_subpath('LinioTests', true)
tests_group.set_source_tree('<group>')
tests_group.set_path('LinioTests')

# Füge Test-Dateien hinzu
test_files = Dir.glob('LinioTests/*.swift')
test_files.each do |file_path|
  file_name = File.basename(file_path)
  file_ref = tests_group.new_file(file_name)
  test_target.source_build_phase.add_file_reference(file_ref)
end

# Füge Info.plist hinzu
info_plist_ref = tests_group.new_file('Info.plist')

# Speichere Projekt
project.save

puts "✅ LinioTests Target erfolgreich hinzugefügt!"
puts "   #{test_files.count} Test-Dateien wurden hinzugefügt."
puts ""
puts "Nächste Schritte:"
puts "1. Öffne das Projekt in Xcode"
puts "2. Drücke Cmd+U um Tests auszuführen"
