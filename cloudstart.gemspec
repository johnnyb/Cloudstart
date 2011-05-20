spec = Gem::Specification.new do |s|
	s.name = "cloudstart"
	s.version = "0.1.0"
	s.summary = "Make managing clouds easier"
	s.description = "Making managing clouds easier"
	s.files = Dir['lib/**/*.rb']
	s.require_path = 'lib'
	s.autorequire = 'cloudstart'
	s.has_rdoc = false
	#s.extra_rdoc_files = Dir['doc/*']
	#s.rdoc_options << 'opt' << 'optvalue' << 'anotheropt'.....
	s.author = 'Jonathan Bartlett'
	s.email = 'jonathan@newmedio.com'
	s.homepage = 'http://www.newmedio.com/'
end
