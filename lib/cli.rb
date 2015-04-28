require 'optparse'
require 'optparse/time'
require 'ostruct'
require 'pp'
require 'multi_json'
require_relative '../lib/datasift'

def to_output(r)
  MultiJson.dump(
    {
      :status => r[:http][:status],
      :headers => r[:http][:headers],
      :body => r[:data]
    },
    :pretty => true
  )
end

def opt(val, default)
  val ? val : default
end

def err(m)
  puts MultiJson.dump(:error => m)
end

def parse(args)
  options = OpenStruct.new
  options.auth = nil
  options.endpoint = 'core'
  options.command = nil
  options.params = {}
  options.api = 'api.datasift.com'

  opt_parser = OptionParser.new do |opts|
    opts.banner = 'Usage: cli.rb [-c] [--api] -a -e [-p*]'
    opts.separator 'Specific options:'

    opts.on('-a', '--auth AUTH', 'DataSift username and API key (formatted as "username api_key")') do |username|
      api_key = ARGV.length > 0 && ARGV[0].index('-') == 0 ? '' : ARGV[0]
      if username.nil? || api_key.nil? || username.empty? || api_key.empty?
        err 'Unable to parse username and API key, they must be in the format username api_key'
        err parse(%w(-h))
        exit
      end
      options.auth = { :username => username, :api_key => api_key }
    end

    opts.on('-e', '--endpoint ENDPOINT', 'Defaults to core, must be one of core, push, historics, preview, sources, pylon') do |e|
      options.endpoint = e
    end

    opts.on('-c', '--command COMMAND', 'DataSift endpoint, depends on the endpoint') do |e|
      options.command = e || 'core'
    end

    opts.on('-p', '--param PARAM', 'Command specific parameters e.g. -p name value') do |k|
      # value is ARGV[0] unless ARGV[0] starts with a hyphen
      options.params[k] = ARGV.length > 0 && ARGV[0].index('-') == 0 ? '' :
        ARGV[0]
    end

    opts.on('-u', '--url API_HOSTNAME', 'Override the API URL') do |e|
      options.api = e
    end

    opts.on('--no-ssl', 'Do not use SSL for API requests') do
      options.enable_ssl = false
    end

    opts.on_tail('-h', '--help', 'Show this message') do
      puts opts
      exit
    end

    opts.on_tail('-v', '--version', 'DataSift client library version') do
      puts DataSift::VERSION
      exit
    end
  end

  opt_parser.parse!(args)
  options
end

def run_core_command(c, command, p)
  case command
  when 'validate'
    c.valid?(p['csdl'], false)
  when 'compile'
    c.compile(p['csdl'])
  when 'usage'
    c.usage(p['period'] ? p['period'].to_sym : :hour)
  when 'balance'
    c.balance
  when 'dpu'
    c.dpu(p['hash'])
  else
    err 'Unknown command for the core endpoint'
    exit
  end
end

def run_historics_command(c, command, p)
  case command
  when 'prepare'
    c.historics.prepare(p['hash'], p['start'], p['end'], p['name'], opt(p['sources'], 'twitter'), opt(p['sample'], 10))
  when 'start'
    c.historics.start(p['id'])
  when 'stop'
    c.historics.stop(p['id'], opt(p['reason'], ''))
  when 'status'
    c.historics.status(p['start'], p['end'], opt(p['sources'], 'twitter'))
  when 'update'
    c.historics.update(p['id'], p['name'])
  when 'delete'
    c.historics.delete(p['id'])
  when 'get'
    c.historics.get(opt(p['max'], 20), opt(p['page'], 1), opt(p['with_estimate'], 1))
  else
    err 'Unknown command for the historics endpoint'
    exit
  end
end

def run_preview_command(c, command, p)
  case command
  when 'create'
    c.historics_preview.create(p['hash'], p['parameters'], p['start'], opt(p['end'], nil))
  when 'get'
    c.historics_preview.get(p['id'])
  else
    err 'Unknown command for the historics preview endpoint'
    exit
  end
end

def run_sources_command(c, command, p)
  case command
  when 'create'
    c.managed_source.create(p['source_type'],p['name'], opt(p['parameters'], {}),
                            opt(p['resources'], []), opt(p['auth'], []))
  when 'update'
    c.managed_source.update(p['id'], p['source_type'], p['name'], opt(p['parameters'], {}),
                            opt(p['resources'], []),
                            opt(p['auth'], []))
  when 'delete'
    c.managed_source.delete(p['id'])
  when 'stop'
    c.managed_source.stop(p['id'])
  when 'start'
    c.managed_source.start(p['id'])
  when 'log'
    c.managed_source.log(p['id'], opt(p['page'], 1), opt(p['per_page'], 20))
  when 'get'
    c.managed_source.get(opt(p['id'], nil), opt(p['source_type'], nil), opt(p['page'], 1), opt(p['per_page'], 20))
  else
    err 'Unknown command for the historics preview endpoint'
    exit
  end
end

def run_push_command(c, command, p)
  case command
  when 'validate'
    c.push.valid? p, false
  when 'create'
    c.push.create p
  when 'pause'
    c.push.pause p['id']
  when 'resume'
    c.push.resume p['id']
  when 'update'
    c.push.update p
  when 'stop'
    c.push.stop p['id']
  when 'delete'
    c.push.delete p['id']
  when 'log'
    p['id'] ?
        c.push.logs_for(p['id'], opt(p['page'], 0), opt(p['per_page'], 20), opt(p['order_by'], :request_time), opt(p['order_dir'], :desc)) :
        c.push.logs(opt(p['page'], 0), opt(p['per_page'], 20), opt(p['order_by'], :request_time), opt(p['order_dir'], :desc))
  when 'get'
    if p['id']
      c.push.get_by_subscription(p['id'], opt(p['page'], 0), opt(p['per_page'], 20), opt(p['order_by'], :request_time))
    elsif p['hash']
      c.push.get_by_hash(p['hash'], opt(p['page'], 0), opt(p['per_page'], 20), opt(p['order_by'], :request_time), opt(p['order_dir'], :desc))
    elsif p['historics_id']
      c.push.get_by_historics_id(p['historics_id'], opt(p['page'], 0), opt(p['per_page'], 20), opt(p['order_by'], :request_time), opt(p['order_dir'], :desc))
    else
      c.push.get(opt(p['page'], 0), opt(p['per_page'], 20), opt(p['order_by'], :request_time), opt(p['order_dir'], :desc))
    end
  when 'pull'
    c.push.pull(p['id'], opt(p['size'], 20971520), opt(p['cursor'], ''))
  else
    err 'Unknown command for the core endpoint'
    exit
  end
end

def run_pylon_command(c, command, p)
  case command
  when 'validate'
    c.pylon.valid?(
      csdl: opt(p['csdl'], ''),
      boolResponse: opt(p['boolResponse'], true)
    )
  when 'compile'
    c.pylon.compile(opt(p['csdl'], ''))
  when 'start'
    c.pylon.start(
      hash: opt(p['hash'], ''),
      name: opt(p['name'], '')
    )
  when 'stop'
    c.pylon.stop(opt(p['hash'], ''))
  when 'get'
    c.pylon.get(opt(p['id'], ''))
  when 'list'
    c.pylon.list
  when 'analyze'
    params = nil
    if p['parameters']
      params = MultiJson.load(p['parameters'])
    end
    c.pylon.analyze(
      hash: opt(p['hash'], ''),
      parameters: params,
      fitler: opt(p['filter'], ''),
      start_time: opt(p['start'], ''),
      end_time: opt(p['end'], '')
    )
  when 'tags'
    c.pylon.tags(p['hash'])
  else
    err 'Unknown command for the pylon endpoint'
    exit
  end
end

def run_account_identity_command(c, command, p)
  case command
  when 'create'
    c.account_identity.create(
      label: opt(p['label'], ''),
      status: opt(p['status'], ''),
      master: opt(p['master'], '')
    )
  when 'get'
    c.account_identity.get(opt(p['id'], ''))
  when 'list'
    c.account_identity.list(
      label: opt(p['label'], ''),
      per_page: opt(p['per_page'], ''),
      page: opt(p['page'], '')
    )
  when 'update'
    c.account_identity.update(
      id: opt(p['id'], ''),
      label: opt(p['label'], ''),
      status: opt(p['status'], ''),
      master: opt(p['master'], '')
    )
  when 'delete'
    c.account_identity.delete(opt(p['id'], ''))
  else
    err 'Unknown command for the account/identity endpoint'
    exit
  end
end

def run_account_token_command(c, command, p)
  case command
  when 'create'
    c.account_identity_token.create(
      identity_id: opt(p['identity_id'], ''),
      service: opt(p['service'], ''),
      token: opt(p['token'], ''),
      expires_at: opt(p['expires_at'], '')
    )
  when 'get'
    c.account_identity_token.get(
      identity_id: opt(p['identity_id'], ''),
      service: opt(p['service'], '')
    )
  when 'list'
    c.account_identity_token.list(
      identity_id: opt(p['identity_id'], ''),
      per_page: opt(p['per_page'], ''),
      page: opt(p['page'], '')
    )
  when 'update'
    c.account_identity_token.update(
      identity_id: opt(p['identity_id'], ''),
      service: opt(p['service'], ''),
      token: opt(p['token'], ''),
      expires_at: opt(p['expires_at'], nil)
    )
  when 'delete'
    c.account_identity_token.delete(
      identity_id: opt(p['identity_id'], ''),
      service: opt(p['service'], '')
    )
  else
    err 'Unknown command for the account/identity/token endpoint'
    exit
  end
end

def run_account_limit_command(c, command, p)
  case command
  when 'create'
    c.account_identity_limit.create(
      identity_id: opt(p['identity_id'], ''),
      service: opt(p['service'], ''),
      total_allowance: opt(p['total_allowance'], nil)
    )
  when 'get'
    c.account_identity_limit.get(
      identity_id: opt(p['identity_id'], ''),
      service: opt(p['service'], '')
    )
  when 'list'
    c.account_identity_limit.list(
      service: opt(p['service'], ''),
      per_page: opt(p['per_page'], ''),
      page: opt(p['page'], '')
    )
  when 'update'
    c.account_identity_limit.update(
      identity_id: opt(p['identity_id'], ''),
      service: opt(p['service'], ''),
      total_allowance: opt(p['total_allowance'], nil)
    )
  when 'delete'
    c.account_identity_limit.delete(
      identity_id: opt(p['identity_id'], ''),
      service: opt(p['service'], '')
    )
  else
    err 'Unknown command for the account/identity/limit endpoint'
    exit
  end
end

begin
  options = parse(ARGV)
  req = [:auth, :command]
  missing = req.select { |param| options.send(param).nil? }
  unless missing.empty?
    err "The following options are required : #{missing.join(', ')}"
    err parse(%w(-h))
    exit
  end

  config = {
    username: options.auth[:username],
    api_key: options.auth[:api_key],
    api_host: options.api
  }
  config.merge!(enable_ssl: options.enable_ssl) unless options.enable_ssl.nil?
  datasift = DataSift::Client.new(config)

  res = case options.endpoint
        when 'core'
          run_core_command(datasift, options.command, options.params)
        when 'historics'
          run_historics_command(datasift, options.command, options.params)
        when 'push'
          run_push_command(datasift, options.command, options.params)
        when 'preview'
          run_preview_command(datasift, options.command, options.params)
        when 'managed_sources'
          run_sources_command(datasift, options.command, options.params)
        when 'pylon'
          run_pylon_command(datasift, options.command, options.params)
        when 'identity'
          run_account_identity_command(datasift, options.command, options.params)
        when 'token'
          run_account_token_command(datasift, options.command, options.params)
        when 'limit'
          run_account_limit_command(datasift, options.command, options.params)
        else
          err 'Unsupported/Unknown endpoint'
          exit
        end
  puts to_output(res)

rescue DataSiftError => e
  err e.message
rescue OptionParser::InvalidOption, OptionParser::MissingArgument
  err $ERROR_INFO.to_s
  err parse(%w(-h))
  exit
end
