Pod::Spec.new do |s|
  s.name             = 'Settler'
  s.version          = '0.1.1'
  s.summary          = 'A utility for building complex, type-safe dependency graphs in Swift'

  s.description      = <<-DESC
  Settler is a Swift metaprogramming tool used to resolve complex dependency
  graphs in a way that encourages code separation and cleanliness while
  maintaining the safety guarantees of the compiler. If an object in your
  resolver cannot be resolved due to a missing or circular dependency, Settler
  will find it and bottom out compilation of your program.
                       DESC

  s.homepage         = 'https://github.com/daltonclaybrook/Settler'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Dalton Claybrook' => 'daltonclaybrook@gmail.com' }
  s.source = { :http => "https://github.com/daltonclaybrook/Settler/releases/download/#{s.version}/Settler-#{s.version}.zip" }
  s.source_files = 'Sources/Settler/**/*'
  s.preserve_paths = '*'

  s.ios.deployment_target = '10.0'
  s.osx.deployment_target  = '10.12'
  s.tvos.deployment_target = '10.0'
  s.watchos.deployment_target = '3.0'

  s.swift_versions = ['5.1', '5.2']

end
