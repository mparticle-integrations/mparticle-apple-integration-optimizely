Pod::Spec.new do |s|
    s.name             = "mParticle-Optimizely"
    s.version          = "7.15.11"
    s.summary          = "Optimizely integration for mParticle"

    s.description      = <<-DESC
                       This is the Optimizely integration for mParticle.
                       DESC

    s.homepage         = "https://www.mparticle.com"
    s.license          = { :type => 'Apache 2.0', :file => 'LICENSE' }
    s.author           = { "mParticle" => "support@mparticle.com" }
    s.source           = { :git => "https://github.com/mparticle-integrations/mparticle-apple-integration-optimizely.git", :tag => s.version.to_s }
    s.social_media_url = "https://twitter.com/mparticle"
    s.dependency 'mParticle-Apple-SDK/mParticle', '~> 7.0'
    s.dependency 'OptimizelySwiftSDK', '~> 3.0'
    s.swift_versions = ['5.0']

    s.ios.deployment_target = "10.0"
    s.ios.source_files      = 'mParticle_Optimizely/*.{h,m,mm}'
    s.ios.frameworks = 'CoreTelephony', 'SystemConfiguration'
    s.libraries = 'z'

    s.tvos.deployment_target = "10.0"
    s.tvos.source_files      = 'mParticle_Optimizely/*.{h,m,mm}'
    s.tvos.frameworks = 'SystemConfiguration'
end
