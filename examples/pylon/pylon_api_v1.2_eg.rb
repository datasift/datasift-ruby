##
# This script runs through all PYLON API endpoints using v1.2 of the API
##

require './../auth'
class AnalysisApi < DataSiftExample
  def initialize
    super
    run_analysis
  end

  def run_analysis
    begin
      puts "Create a new identity to make PYLON API calls"
      identity = @datasift.account_identity.create(
        "RUBY_LIB_#{Time.now.to_i}",
        "active",
        false
      )
      identity_id = identity[:data][:id]
      puts identity[:data].to_json

      puts "\nCreate a Token for our Identity"
      token = @datasift.account_identity_token.create(
        identity_id,
        'facebook',
        '125595667777713|5aef9cfdb31d8be64b87204c3bca820f'
      )
      puts token[:data].to_json

      puts "\nNow make PYLON API calls using the Identity's API key"
      @config.merge!(
        api_key: identity[:data][:api_key],
        api_version: 'v1.2'
      )
      @datasift = DataSift::Client.new(@config)

      csdl = "return { fb.content any \"data, #{Time.now}\" }"

      puts "Check this CSDL is valid: #{csdl}"
      puts "Valid? #{@datasift.pylon.valid?(csdl)}"

      puts "\nCompile my CSDL"
      compiled = @datasift.pylon.compile csdl
      hash = compiled[:data][:hash]
      puts "Hash: #{hash}"

      puts "\nStart recording filter with hash #{hash}"
      filter = @datasift.pylon.start(
        hash,
        'Facebook Pylon Test Filter'
      )
      puts filter[:data].to_json

      puts "\nSleep for 10 seconds to record a little data"
      sleep(10)

      puts "\nGet details of our running recording"
      puts @datasift.pylon.get(hash)[:data].to_json

      puts "\nYou can also list running recordings"
      puts @datasift.pylon.list[:data].to_json

      puts "\nFrequency distribution analysis on fb.author.country"
      params = {
        analysis_type: 'freqDist',
        parameters: {
          threshold: 1,
          target: 'fb.author.country'
        }
      }
      puts @datasift.pylon.analyze(
        hash,
        params
      )[:data].to_json

      puts "\nFrequency distribution analysis on fb.author.age with filter"
      params = {
        analysis_type: 'freqDist',
        parameters: {
          threshold: 1,
          target: 'fb.author.age'
        }
      }
      filter = ''
      puts @datasift.pylon.analyze(
        hash,
        params,
        filter
      )[:data].to_json

      puts "\nTime series analysis"
      params = {
        analysis_type: 'timeSeries',
        parameters: {
          interval: 'hour',
          span: 12
        }
      }
      filter = ''
      start_time = Time.now.to_i - (60 * 60 * 24 * 7) # 7 days ago
      end_time = Time.now.to_i
      puts @datasift.pylon.analyze(
        hash,
        params,
        filter,
        start_time,
        end_time
      )[:data].to_json

      puts "\nFrequency Distribution with nested queries. Find the top three " \
        "age groups for each gender by country"
      filter = ''
      params = {
        analysis_type: 'freqDist',
        parameters: {
          threshold: 4,
          target: 'fb.author.country'
        },
        child: {
          analysis_type: 'freqDist',
          parameters: {
            threshold: 2,
            target: 'fb.author.gender'
          },
          child: {
            analysis_type: 'freqDist',
            parameters: {
              threshold: 3,
              target: 'fb.author.age'
            }
          }
        }
      }
      start_time = Time.now.to_i - (60 * 60 * 24 * 7)
      end_time = Time.now.to_i
      puts @datasift.pylon.analyze(
        hash,
        params,
        filter,
        start_time,
        end_time
      )[:data].to_json

      puts "\nTags analysis"
      puts @datasift.pylon.tags(hash)[:data].to_json

      puts "\nGet Public Posts"
      puts @datasift.pylon.sample(
        hash,
        10,
        Time.now.to_i - (60 * 60), # from 1hr ago
        Time.now.to_i, # to 'now'
        'fb.content contains_any "your, filter, terms"'
      )[:data].to_json

      puts "\nStop recording filter with hash #{hash}"
      puts @datasift.pylon.stop(hash)[:data].to_json

      rescue DataSiftError => dse
        puts dse.inspect
    end
  end
end

AnalysisApi.new
