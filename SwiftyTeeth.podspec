Pod::Spec.new do |s|
  s.name             = 'SwiftyTeeth'
  s.version          = '0.6.1'
  s.summary          = 'A simple, lightweight library intended to take away some of the cruft and tediousness of using CoreBluetooth.'
  s.description      = <<-DESC
A simple, lightweight library intended to take away some of the cruft and tediousness of using CoreBluetooth. 

It replaces CoreBluetooth's protocols and delegates with a block-based pattern, and handles much of the code overhead associated with handling connections, discovery, reads/writes, and notifications.
                       DESC

  s.homepage         = 'https://github.com/RobotPajamas/SwiftyTeeth'
  s.license          = { :type => 'Apache', :file => 'LICENSE' }
  s.authors          = ['basememara', 'sureshjoshi']
  s.source           = { :git => 'https://github.com/RobotPajamas/SwiftyTeeth.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '10.0'

  s.source_files = 'Sources/**/*'

  s.frameworks = 'CoreBluetooth'
end
