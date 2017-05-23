#!/usr/bin/env ruby
require 'digest'

email = 'fdipilla@gmail.com'
name, host = email.split("@")
print [Digest::SHA1.hexdigest(name), host].compact.join("@")
