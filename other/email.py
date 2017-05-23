#!/usr/bin/env python

"""
githubarchive uses sha1 hexdigest to obfuscate emails
https://github.com/igrigorik/githubarchive.org/blob/master/crawler/crawler.rb#L41

```ruby
name, host = email.split("@")
h['email'] = [Digest::SHA1.hexdigest(name), host].compact.join("@")
```
"""

import hashlib

email_in = 'leekebremer@gmail.com'
email_out = '4b1d48ee03363c455483a0391e0b2f25173136a1@gmail.com'
name, host = email_in.split('@')

print(hashlib.sha1(email_in.encode('ascii')).hexdigest())


