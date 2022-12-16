Pod::Spec.new do |s|
  s.name             = 'CocoMediaPlayer'
  s.version          = '0.1.0'
  s.summary          = 'A real-time media player for coco platfrom.'

  s.description      = <<-DESC
  A real-time media player implementation to work with coco platform products.
  DESC

  s.homepage         = 'https://github.com/ashishbajaj99/cocomediaplayer-swift'
  s.license          = { :type => 'Commercial', :file => 'LICENSE' }
  s.authors          = {  'rohan-elear' => 'rohansahay@elear.solutions',
                          'shrinivas-elear' => 'shrinivasgutte@elear.solutions' }
  s.source           = {  :git => 'https://github.com/ashishbajaj99/cocomediaplayer-swift.git',
                          :tag => "#{s.version}" }

  s.swift_version = '5'
  s.platform = [:ios]
  s.ios.deployment_target = '12.0'
  s.source_files = 'CocoMediaPlayer/**/*.swift'
end

