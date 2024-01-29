
Pod::Spec.new do |s|
    s.name          = 'BTFuse'
    s.version       = '0.8.3'
    s.summary       = 'A native-first framework for building hybrid native-web applications.'
    s.homepage      = 'https://fuse.breautek.com'
    s.license       = {
        :type => 'Apache-2.0',
        :file => 'LICENSE'
    }
    s.author        = { 'BTFuse' => 'norman@breautek.com' }
    s.ios.deployment_target = '15.0'
    s.source        = {
        :http => 'https://github.com/btfuse/fuse-ios/releases/download/0.8.3/BTFuse.xcframework.zip'
    }

    s.vendored_frameworks = 'BTFuse.xcframework'
end