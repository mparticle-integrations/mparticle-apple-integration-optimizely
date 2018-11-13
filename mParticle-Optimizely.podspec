Pod::Spec.new do |s|
    s.name             = "mParticle-Optimizely"
    s.version          = "7.6.0"
    s.summary          = "Optimizely integration for mParticle"

    s.description      = <<-DESC
                       This is the Optimizely integration for mParticle.
                       DESC

    s.homepage         = "https://www.mparticle.com"
    s.license          = { :type => 'Apache 2.0', :file => 'LICENSE' }
    s.author           = { "mParticle" => "support@mparticle.com" }
    s.source           = { :git => "https://github.com/mparticle-integrations/mparticle-apple-integration-optimizely.git", :tag => s.version.to_s }
    s.social_media_url = "https://twitter.com/mparticles"

    s.ios.deployment_target = "8.0"
    s.ios.source_files      = 'mParticle-Optimizely/*.{h,m,mm}'
    s.ios.dependency 'mParticle-Apple-SDK/mParticle', '~> 7.6.0'
    s.ios.frameworks = 'CoreTelephony', 'SystemConfiguration'
    s.libraries = 'z'
    s.ios.dependency 'OptimizelySDKiOS', '~> 2.1.3'

    s.tvos.deployment_target = "9.0"
    s.tvos.source_files      = 'mParticle-Optimizely/*.{h,m,mm}'
    s.tvos.dependency 'mParticle-Apple-SDK/mParticle', '~> 7.6.0'
    s.tvos.frameworks = 'SystemConfiguration'
    s.tvos.dependency 'OptimizelySDKTVOS', '~> 2.1.3'
    
    s.tvos.pod_target_xcconfig = {
        'LIBRARY_SEARCH_PATHS' => '$(inherited) $(PODS_ROOT)/OptimizelySDKTVOS/**'
    }
end
