$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "image/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "image"
  s.version     = Image::VERSION
  s.authors     = ["Andreas Pfau"]
  s.email       = ["andreas.pfau@sap.com"]
  s.homepage    = ""
  s.summary     = "Summary of Image."
  s.description = "Description of Image."

  s.files = Dir["{app,config,db,lib}/**/*","README.rdoc"]
  s.test_files = Dir["spec/**/*"]

end
