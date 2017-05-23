## Getting Started
- `git clone https://github.com/librariesio/github-firehose.git`
- `npm install github-firehose/`

## Github Archive
- githubarchive is currently 60GB
- but email addresses are SHA1 encoded ;(
- githubarchive uses sha1 hexdigest to obfuscate emails
- https://github.com/igrigorik/githubarchive.org/blob/master/crawler/crawler.rb#L41

## Github Crawl
- bigquery: `SELECT count(distinct actor.login) FROM (TABLE_DATE_RANGE([githubarchive:day.], TIMESTAMP('2017-01-01'), TIMESTAMP('2017-05-01')))` => 4.1M
- >>4M active users
- web profiles accessible i.e. from AWS

## Github API
- https://developer.github.com/v3/#rate-limiting
    - logged in user 5000 req/hour
    - anonymous user/IP 60 req/hour

## Github raw events have emails in clear text
- https://github.com/paulirish/github-email/blob/master/github-email.sh 
    - https://api.github.com/users/$user
        - email info always nulled out
    - https://registry.npmjs.org/-/user/org.couchdb.user:$user
        - npm info with same handle
    - Emails from recent commits
        - https://api.github.com/users/$user/events
    - Emails from owned-repo recent activity
        - https://api.github.com/users/$user/repos?type=owner&sort=updated
        - https://api.github.com/repos/$user/$repo/commits
- 
