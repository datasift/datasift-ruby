module DataSift
  #
  # Class for accessing DataSift's PYLON API
  class Pylon < DataSift::ApiResource
    # Check PYLON CSDL is valid by making an /pylon/validate API call
    #
    # @param csdl [String] CSDL you wish to validate
    # @param boolResponse [Boolean] True if you want a boolean response.
    #   False if you want the full response object
    # @return [Boolean, Object] Dependent on value of boolResponse
    def valid?(csdl = '', boolResponse = true)
      fail BadParametersError, 'csdl is required' if csdl.empty?
      params = { csdl: csdl }

      res = DataSift.request(:POST, 'pylon/validate', @config, params)
      boolResponse ? res[:http][:status] == 200 : res
    end

    # Compile PYLON CSDL by making an /pylon/compile API call
    #
    # @param csdl [String] CSDL you wish to compile
    # @return [Object] API reponse object
    def compile(csdl)
      fail BadParametersError, 'csdl is required' if csdl.empty?
      params = { csdl: csdl }

      DataSift.request(:POST, 'pylon/compile', @config, params)
    end

    # Perform /pylon/get API call to query status of your PYLON recordings
    #
    # @param hash [String] Hash you with the get the status for
    # @param id [String] The ID of the PYLON recording to get
    # @return [Object] API reponse object
    def get(id='')
      fail BadParametersError, 'hash or id is required' if id.empty?
      params = {}
      params.merge!(id: id) unless id.empty?

      DataSift.request(:GET, 'pylon/get', @config, params)
    end

    # Perform /pylon/get API call to list all PYLON Recordings
    #
    # @param page [Integer] Which page of recordings to retreive
    # @param per_page [Integer] How many recordings to return per page
    # @param order_by [String, Symbol] Which field to sort results by
    # @param order_dir [String, Symbol] Order results in ascending or descending
    #   order
    # @return [Object] API reponse object
    def list(page = nil, per_page = nil, order_by = '', order_dir = '')
      params = {}
      params.merge!(page: page) unless page.nil?
      params.merge!(per_page: per_page) unless per_page.nil?
      params.merge!(order_by: order_by) unless order_by.empty?
      params.merge!(order_dir: order_dir) unless order_dir.empty?

      DataSift.request(:GET, 'pylon/get', @config, params)
    end

    # Perform /pylon/update API call to update a given PYLON Recording
    #
    # @param id [String] The ID of the PYLON recording to update
    # @param hash [String] The CSDL filter hash this recording should be subscribed to
    # @param name [String] Update the name of your recording
    # @return [Object] API reponse object
    def update(id, hash = '', name = '')
      params = {id: id}
      params.merge!(hash: hash) unless hash.empty?
      params.merge!(name: name) unless name.empty?

      DataSift.request(:PUT, 'pylon/update', @config, params)
    end

    # Start recording a PYLON filter by making an /pylon/start API call
    #
    # @param hash [String] CSDL you wish to begin (or resume) recording
    # @param name [String] Give your recording a name. Required when starting a
    # @param id [String] ID of the recording you wish to start
    #   new recording
    # @return [Object] API reponse object
    def start(hash = '', name = '', id = '')
      fail BadParametersError, 'hash or id is required' if hash.empty? && id.empty?
      params = {}
      params.merge!(hash: hash) unless hash.empty?
      params.merge!(name: name) unless name.empty?
      params.merge!(id: id) unless id.empty?

      DataSift.request(:PUT, 'pylon/start', @config, params)
    end

    # Restart an existing PYLON recording by making an /pylon/start API call with a recording ID
    #
    # @param id [String] CSDL you wish to begin (or resume) recording
    # @param name [String] Give your recording a name. Required when starting a
    #   new recording
    # @return [Object] API reponse object
    def restart(id, name = '')
      fail BadParametersError, 'id is required' if id.empty?
      params = { id: id }
      params.merge!(name: name) unless name.empty?

      DataSift.request(:PUT, 'pylon/start', @config, params)
    end

    # Stop an active PYLON recording by making an /pylon/stop API call
    #
    # @param hash [String] CSDL you wish to stop recording
    # @param id [String] ID of the recording you wish to stop
    # @return [Object] API reponse object
    def stop(id = '')
      fail BadParametersError, 'hash or id is required' if id.empty?
      params = {}
      params.merge!(id: id) unless id.empty?

      DataSift.request(:PUT, 'pylon/stop', @config, params)
    end

    # Perform a PYLON analysis query by making an /pylon/analyze API call
    #
    # @param hash [String] Hash of the recording you wish to perform an
    #   analysis against
    # @param parameters [String] Parameters of the analysis you wish to perform.
    #   See the
    #   {http://dev.datasift.com/pylon/docs/api-endpoints/pylonanalyze
    #   /pylon/analyze API Docs} for full documentation
    # @param filter [String] Optional PYLON CSDL for a query filter
    # @param start_time [Integer] Optional start timestamp for filtering by date
    # @param end_time [Integer] Optional end timestamp for filtering by date
    # @param id [String] ID of the recording you wish to analyze
    # @return [Object] API reponse object
    def analyze(id = '', parameters = '', filter = '', start_time = nil, end_time = nil)
      fail BadParametersError, 'hash or id is required' if id.empty?
      fail BadParametersError, 'parameters is required' if parameters.empty?
      params = { parameters: parameters }
      params.merge!(id: id) unless id.empty?
      params.merge!(filter: filter) unless filter.empty?
      params.merge!(start: start_time) unless start_time.nil?
      params.merge!(end: end_time) unless end_time.nil?

      DataSift.request(:POST, 'pylon/analyze', @config, params)
    end

    # Query the tag hierarchy on interactions populated by a particular
    #   recording
    #
    # @param hash [String] Hash of the recording you wish to query
    # @param id [String] ID of the recording you wish to query
    # @return [Object] API reponse object
    def tags(id = '')
      fail BadParametersError, 'hash or id is required' if id.empty?
      params = {}
      params.merge!(id: id) unless id.empty?

      DataSift.request(:GET, 'pylon/tags', @config, params)
    end

    # Hit the PYLON Sample endpoint to pull public sample data from a PYLON recording
    #
    # @param hash [String] The CSDL hash that identifies the recording you want to sample
    # @param count [Integer] Optional number of public interactions you wish to receive
    # @param start_time [Integer] Optional start timestamp for filtering by date
    # @param end_time [Integer] Optional end timestamp for filtering by date
    # @param filter [String] Optional PYLON CSDL for a query filter
    # @param id [String] ID of the recording you wish to sample
    # @return [Object] API reponse object
    def sample(id = '', count = nil, start_time = nil, end_time = nil, filter = '')
      fail BadParametersError, 'hash or id is required' if id.empty?
      params = {}
      params.merge!(id: id) unless id.empty?
      params.merge!(count: count) unless count.nil?
      params.merge!(start: start_time) unless start_time.nil?
      params.merge!(end: end_time) unless end_time.nil?

      if filter.empty?
        DataSift.request(:GET, 'pylon/sample', @config, params)
      else
        params.merge!(filter: filter)
        DataSift.request(:POST, 'pylon/sample', @config, params)
      end
    end
  end
end
