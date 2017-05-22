require File.expand_path('../../test_helper', __FILE__)

describe 'DataSift::HistoricsPreview' do
  before do
    @datasift = DataSiftExample.new.datasift

    @data = OpenStruct.new
    @data.valid_csdl = 'interaction.content contains "ruby"'
    @data.sources = 'tumblr'
    @data.parameters = 'language.tag,freqDist,5;interaction.id,targetVol,hour'
    @data.start = 1477958400
    @data.end = 1478044800
  end

  ##
  # /preview/create
  #
  describe '#create' do
    before do
      VCR.use_cassette("#{@datasift.config[:api_version]}" + '/preview/before_preview_create') do
        @hash = @datasift.compile(@data.valid_csdl)[:data][:hash]
      end
    end

    it 'can_create_historics_preview' do
      VCR.use_cassette("#{@datasift.config[:api_version]}" + '/preview/preview_create_success') do
        response = @datasift.historics_preview.create(
          @hash, @data.sources, @data.parameters, @data.start, @data.end
        )
        assert_equal STATUS.accepted, response[:http][:status]
      end
    end
  end

  ##
  # /preview/get
  #
  describe '#get' do
    before do
      VCR.use_cassette("#{@datasift.config[:api_version]}" + '/preview/before_preview_get') do
        @hash = @datasift.compile(@data.valid_csdl)[:data][:hash]
        @preview = @datasift.historics_preview.create(
          @hash, @data.sources, @data.parameters, @data.start, @data.end
        )
      end
    end

    it 'can get an Historics Preview' do
      VCR.use_cassette("#{@datasift.config[:api_version]}" + '/preview/preview_get_success') do
        response = @datasift.historics_preview.get(@preview[:data][:id])
        assert_equal STATUS.accepted, response[:http][:status]
      end
    end
  end
end
