Pod::Spec.new do |s|
  s.name         = "ELRemotePlistFile"
  s.version      = "1.0.0"
  s.summary      = "A helper iOS class to download & cache plist file hosted on a remote server."
  s.homepage     = "https://github.com/eddieespinal/ELRemotePlistFile"
  s.license      = "APACHE"
  s.authors      = { "Eddie Espinal" => "eddieespinal@gmail.com" }
  s.source       = { :git => "https://github.com/eddieespinal/ELRemotePlistFile.git" }
  s.platform     = :ios, '5.0'
  s.source_files = 'ELRemotePlistFile'
  s.requires_arc = true
end
