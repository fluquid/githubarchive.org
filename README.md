# GitHub Archive

fork of https://github.com/igrigorik/githubarchive.org.

- removed `bigquery` folder
- minor modifications in `crawler` to run outside heroku

## Getting Started
- `cd crawler`
- `sudo bundle install` (figure out how to isolate env)
- `sudo gem install em-http-request`
- set `GITHUB_TOKEN` on env
