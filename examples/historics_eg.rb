require './auth'
class HistoricsApi < DataSiftExample
  def initialize
    super
    run_historics
  end

  def run_historics
    begin
      stream   = @datasift.compile 'interaction.content contains "datasift"'
      hash     = stream[:data][:hash]
      start    = Time.now.to_i - 10800
      end_time = start + 3600

      puts 'Check the data coverage for this Historic period'
      puts @datasift.historics.status(start, end_time)

      puts "\nPreparing"
      # Prepare an Historics query to start from three hours ago and run for 1
      #   hour using Tumblr as a data source and using only a 10% sample
      historics = @datasift.historics.prepare(
        hash, start, end_time, 'My ruby historics', 'tumblr', 10
      )
      puts historics

      id = historics[:data][:id]

      puts "\nCheck the DPU cost of this Historics query"
      puts "#{@datasift.dpu('', id)[:data][:dpu]} DPUs"

      puts "\nCreating push subscription for historics"
      subscription = create_push(id, true)

      puts "\nStarting historics #{id}"
      puts @datasift.historics.start id

      puts "\nPausing historics #{id}"
      puts @datasift.historics.pause id

      puts "\nResuming historics #{id}"
      puts @datasift.historics.resume id

      puts "\nUpdating historics"
      puts @datasift.historics.update(id, 'The new name of my historics')

      puts "\nGet info for the historics"
      puts @datasift.historics.get_by_id id

      puts "\nGetting info for all my historics"
      puts @datasift.historics.get

      puts "\nStopping historics"
      puts @datasift.historics.stop id

      puts "\nDeleting historics"
      puts @datasift.historics.delete id

      puts "\nCleanup and delete Push subscription"
      puts @datasift.push.delete subscription[:data][:id]
    rescue DataSiftError => dse
      puts dse.message
    end
  end
end

HistoricsApi.new
