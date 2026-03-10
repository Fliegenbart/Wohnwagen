require 'fileutils'
require 'pathname'
require 'rubygems'
require 'xcodeproj'

ROOT = File.expand_path('..', __dir__)
PROJECT_PATH = File.join(ROOT, 'CamperReady.xcodeproj')

FileUtils.rm_rf(PROJECT_PATH)

project = Xcodeproj::Project.new(PROJECT_PATH)
project.root_object.attributes['LastUpgradeCheck'] = '2600'
project.root_object.attributes['TargetAttributes'] = {}

app_target = project.new_target(:application, 'CamperReady', :ios, '17.0')
test_target = project.new_target(:unit_test_bundle, 'CamperReadyTests', :ios, '17.0')
test_target.add_dependency(app_target)

def configure_target(target, bundle_id, test_host_path: nil)
  target.build_configurations.each do |config|
    config.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = bundle_id
    config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '17.0'
    config.build_settings['SWIFT_VERSION'] = '5.0'
    config.build_settings['SWIFT_EMIT_LOC_STRINGS'] = 'NO'
    config.build_settings['GENERATE_INFOPLIST_FILE'] = 'YES'
    config.build_settings['CODE_SIGN_STYLE'] = 'Automatic'
    config.build_settings['TARGETED_DEVICE_FAMILY'] = '1'
    config.build_settings['MARKETING_VERSION'] = '1.0'
    config.build_settings['CURRENT_PROJECT_VERSION'] = '1'
    config.build_settings['SWIFT_STRICT_CONCURRENCY'] = 'minimal'
    config.build_settings['ASSETCATALOG_COMPILER_APPICON_NAME'] = 'AppIcon'
    config.build_settings['ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME'] = ''
    config.build_settings['INFOPLIST_KEY_UILaunchScreen_Generation'] = 'YES'
    config.build_settings['INFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone'] = 'UIInterfaceOrientationPortrait'
    config.build_settings['LD_RUNPATH_SEARCH_PATHS'] = '$(inherited) @executable_path/Frameworks'
    next unless test_host_path

    config.build_settings['BUNDLE_LOADER'] = test_host_path
    config.build_settings['TEST_HOST'] = test_host_path
    config.build_settings['LD_RUNPATH_SEARCH_PATHS'] = '$(inherited) @loader_path/Frameworks @executable_path/Frameworks'
  end
end

configure_target(app_target, 'com.camperready.app')
configure_target(test_target, 'com.camperready.appTests', test_host_path: '$(BUILT_PRODUCTS_DIR)/CamperReady.app/CamperReady')

main_group = project.main_group
source_group = main_group.find_subpath('CamperReady', true)
test_group = main_group.find_subpath('CamperReadyTests', true)
scripts_group = main_group.find_subpath('Scripts', true)
scripts_group.set_source_tree('<group>')

def ensure_group(root_group, relative_directory)
  return root_group if relative_directory == '.' || relative_directory.empty?

  relative_directory.split('/').inject(root_group) do |group, path_component|
    group[path_component] || group.new_group(path_component)
  end
end

def add_files(project:, root_group:, target:, base_directory:)
  Dir.glob(File.join(base_directory, '**', '*.{swift,md}')).sort.each do |absolute_path|
    relative_path = Pathname.new(absolute_path).relative_path_from(Pathname.new(ROOT)).to_s
    relative_directory = File.dirname(relative_path)
    group = ensure_group(root_group, relative_directory.sub("#{root_group.display_name}/", ''))
    file_ref = group.files.find { |ref| ref.path == relative_path } || group.new_file(relative_path)
    target.source_build_phase.add_file_reference(file_ref) if absolute_path.end_with?('.swift')
  end
end

def add_asset_catalogs(root_group:, target:, base_directory:)
  Dir.glob(File.join(base_directory, '**', '*.xcassets')).sort.each do |absolute_path|
    relative_path = Pathname.new(absolute_path).relative_path_from(Pathname.new(ROOT)).to_s
    relative_directory = File.dirname(relative_path)
    group = ensure_group(root_group, relative_directory.sub("#{root_group.display_name}/", ''))
    file_ref = group.files.find { |ref| ref.path == relative_path } || group.new_file(relative_path)
    target.resources_build_phase.add_file_reference(file_ref)
  end
end

add_files(project: project, root_group: source_group, target: app_target, base_directory: File.join(ROOT, 'CamperReady'))
add_files(project: project, root_group: test_group, target: test_target, base_directory: File.join(ROOT, 'CamperReadyTests'))
add_asset_catalogs(root_group: source_group, target: app_target, base_directory: File.join(ROOT, 'CamperReady'))

project.save

scheme = Xcodeproj::XCScheme.new
scheme.configure_with_targets(app_target, test_target)
scheme.save_as(PROJECT_PATH, 'CamperReady', true)

puts "Generated #{PROJECT_PATH}"
