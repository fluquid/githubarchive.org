require 'log4r'
require 'yajl'
require 'digest'
require 'em-http'
require 'zlib'
#require 'em-stathat'

include EM

##
## Setup
##

=begin
StatHat.config do |c|
  c.ukey  = ENV['STATHATKEY']
  c.email = 'ilya@igvita.com'
end
=end

@log = Log4r::Logger.new('github')
@log.add(Log4r::StdoutOutputter.new('console', {
  :formatter => Log4r::PatternFormatter.new(:pattern => "[#{Process.pid}:%l] %d :: %m")
}))

##
## Crawler
##

@file = nil
@rawfile = nil
EM.run do
  stop = Proc.new do
    if !@rawfile.nil?
      @file.close
      @rawfile.close
    end
    puts "Terminating crawler"
    EM.stop
  end

  Signal.trap("INT",  &stop)
  Signal.trap("TERM", &stop)

  @latest = []
  @latest_key = lambda { |e| "#{e['id']}" }
  @clean = lambda do |h|
    if email = h.delete('email')
      name, host = email.split("@")
      h['email'] = email
      if !name.nil? and !host.nil?
          h['email_hash'] = [Digest::SHA1.hexdigest(name), host].compact.join("@")
      end
    end
    h.each_value do |v|
      @clean.call(v) if v.is_a? Hash
      v.each {|e| @clean.call(e)} if v.is_a? Array
    end
  end

  process = Proc.new do
      req = HttpRequest.new("https://api.github.com/events?per_page=200", {
        :inactivity_timeout => 5,
        :connect_timeout => 5
      }).get({
      :head => {
        'user-agent' => 'githubarchive_codinguncut',
        'Authorization' => 'token ' + ENV['GITHUB_TOKEN']
      }
    })

    req.callback do
      begin
        latest = Yajl::Parser.parse(req.response)
        urls = latest.collect(&@latest_key)
        new_events = latest.reject {|e| @latest.include? @latest_key.call(e)}

        @latest = urls
        new_events.sort_by {|e| [Time.parse(e['created_at']), e['id']] }.each do |event|
          timestamp = Time.parse(event['created_at']).strftime('%Y-%m-%d-%-k')
          archive = "data/#{timestamp}.json.gz"

          if @rawfile.nil? || (archive != @rawfile.to_path)
            if !@rawfile.nil?
              @log.info "Rotating archive. Current: #{@rawfile.to_path}, New: #{archive}"
              @file.close
              @rawfile.close
            end

            @rawfile = File.new(archive, "a+")
            @file = Zlib::GzipWriter.new(@rawfile)
          end

          @file.puts(Yajl::Encoder.encode(@clean.call(event)))
        end

        remaining = req.response_header.raw['X-RateLimit-Remaining']
        reset = Time.at(req.response_header.raw['X-RateLimit-Reset'].to_i)
        #@log.info "Found #{new_events.size} new events: #{new_events.collect(&@latest_key)}, API: #{remaining}, reset: #{reset}"
        @log.info "Found #{new_events.size} new events, API: #{remaining}, reset: #{reset}"

        if new_events.size >= 100
          @log.info "Missed records.."
        end

        #StatHat.new.ez_count('Github Events', new_events.size)

      rescue Exception => e
        @log.error "Processing exception: #{e}, #{e.backtrace.first(5)}"
        @log.error "Response: #{req.response_header}, #{req.response}"
      ensure
        EM.add_timer(1.5, &process)
      end
    end

    req.errback do
      @log.error "Error: #{req.response_header.status}, \
                  header: #{req.response_header}, \
                  response: #{req.response}"

      EM.add_timer(1.5, &process)
    end
  end

  process.call
end
