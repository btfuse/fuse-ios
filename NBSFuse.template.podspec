
Pod::Spec.new do |s|
  s.name             = 'NBSFuse'
  s.version          = ':VERSION:'
  s.summary          = 'NBS Fuse'

  s.description      = <<-DESC
A native-first framework for building hybrid native-web applications.
                       DESC

  s.homepage         = 'https://github.com/nbsfuse/fuse'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'Apache-2.0', :file => 'NBSFuse/LICENSE' }
  s.author           = { 'Norman Breau' => 'norman@nbsolutions.ca' }
  s.ios.deployment_target = '13.0'

  s.subsec 'src' do |source|
    source.source = {
      :git => 'https://github.com/nbsfuse/fuse-ios.git'
      :tag => ':VERSION:'
    }
    source.source_files = 'NBSFuse/**/*.{h,m}'
    source.public_header_files = 'NBSFuse/NBSFuse/*.h'
  end

  s.subspec 'bin' do |binary|
    binary.source = {
      :http => 'https://github.com/nbsfuse/fuse-ios/releases/download/:VERSION:/NBSFuse.zip',
      :sha1 => ':CHECKSUM:'
    }
    binary.vendored_frameworks = 'NBSFuse/NBSFuse.xcframework'
  end
end
