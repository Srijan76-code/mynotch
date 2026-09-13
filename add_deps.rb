require 'xcodeproj'

project_path = 'mynotch.xcodeproj'
project = Xcodeproj::Project.open(project_path)

target = project.targets.first

def add_package(project, target, url, requirement)
  # Check if already added
  return if project.root_object.package_references.any? { |p| p.repositoryURL == url }
  
  pkg = project.new(Xcodeproj::Project::Object::XCRemoteSwiftPackageReference)
  pkg.repositoryURL = url
  pkg.requirement = requirement
  project.root_object.package_references << pkg
  
  # Get product name from URL (heuristic)
  product_name = url.split('/').last.sub('.git', '')
  product_name = "DynamicNotch" if product_name == "DynamicNotchKit"
  product_name = "LaunchAtLogin" if product_name == "LaunchAtLogin-Modern"
  
  ref = project.new(Xcodeproj::Project::Object::XCSwiftPackageProductDependency)
  ref.package = pkg
  ref.product_name = product_name
  
  # Add to frameworks build phase
  frameworks_phase = target.frameworks_build_phase
  build_file = project.new(Xcodeproj::Project::Object::PBXBuildFile)
  build_file.product_ref = ref
  frameworks_phase.files << build_file
end

add_package(project, target, 'https://github.com/MrKai77/DynamicNotchKit', { 'kind' => 'upToNextMajorVersion', 'minimumVersion' => '0.0.1' })
add_package(project, target, 'https://github.com/EmergeTools/Pow', { 'kind' => 'upToNextMajorVersion', 'minimumVersion' => '1.0.0' })
add_package(project, target, 'https://github.com/sindresorhus/Defaults', { 'kind' => 'upToNextMajorVersion', 'minimumVersion' => '7.0.0' })
add_package(project, target, 'https://github.com/sindresorhus/KeyboardShortcuts', { 'kind' => 'upToNextMajorVersion', 'minimumVersion' => '1.0.0' })
add_package(project, target, 'https://github.com/sindresorhus/LaunchAtLogin-Modern', { 'kind' => 'upToNextMajorVersion', 'minimumVersion' => '1.0.0' })
add_package(project, target, 'https://github.com/SFSafeSymbols/SFSafeSymbols', { 'kind' => 'upToNextMajorVersion', 'minimumVersion' => '4.0.0' })
add_package(project, target, 'https://github.com/johnno1962/HotReloading', { 'kind' => 'upToNextMajorVersion', 'minimumVersion' => '1.0.0' })

project.save
puts "Added Swift Packages to project!"
