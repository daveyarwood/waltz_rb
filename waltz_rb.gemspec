Gem::Specification.new do |s|
  s.name        = 'waltz_rb'
  s.version     = '0.0.3'
  s.date        = '2016-09-13'
  s.summary     = "Ruby runtime for the Waltz music theory DSL"
  s.description = <<-EOF
    Waltz is a portable music theory library implemented in Forth.

    waltz_rb provides an implementation of a Forth interpreter that can
    load the Waltz library and evaluate strings of Waltz code.
  EOF
  s.authors     = ["Dave Yarwood"]
  s.email       = 'dave.yarwood@gmail.com'
  s.files       = ["lib/waltz.rb"]
  s.homepage    = 'https://github.com/daveyarwood/waltz_rb'
  s.license     = 'Eclipse Public License'
end
