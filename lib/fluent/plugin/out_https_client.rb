class Fluent::HTTPSOutput < Fluent::Output
  Fluent::Plugin.register_output('https_client', self)

  def initialize
    super
    require 'net/https'
    require 'openssl'
    require 'uri'
    require 'yajl'
  end

  config_param :use_ssl, :bool, :default => false
  config_param :include_tag, :bool, :default => false
  config_param :include_timestamp, :bool, :default => false
  config_param :endpoint_url, :string
  config_param :http_method, :string, :default => :post
  config_param :serializer, :string, :default => :form
  config_param :rate_limit_msec, :integer, :default => 10
  config_param :auth, :string, :default => nil
  config_param :username, :string, :default => ''
  config_param :password, :string, :default => ''
  config_param :proxy_addr, :string, :default => ''
  config_param :proxy_port, :integer, :default => -1

  

 def configure(conf)
    super

    @use_ssl = conf['use_ssl']
    @include_tag = conf['include_tag']
    @include_timestamp = conf['include_timestamp']


    @use_proxy = false
    if @proxy_port and @proxy_addr
      # check for proxy settings
      if @proxy_port > 0 and @proxy_addr.empty?
        raise Fluent::ConfigError, 'HTTPS Output :: provide a valid proxy address'
      elsif  @proxy_port <= 0 and !@proxy_addr.empty?
        raise Fluent::ConfigError, 'HTTPS Output :: provide a valid proxy port number'
      elsif @proxy_port == 0
        raise Fluent::ConfigError, 'HTTPS Output :: provide a valid proxy port number'
      elsif  @proxy_port > 0 and !@proxy_addr.empty?
        @use_proxy = true
      end
    end

    serializers = [:json, :form]
    @serializer = if serializers.include? @serializer.intern
                    @serializer.intern
                  else
                    :form
                  end

    http_methods = [:get, :put, :post, :delete]
    @http_method = if http_methods.include? @http_method.intern
                    @http_method.intern
                  else
                    :post
                  end

    @auth = case @auth
            when 'basic' then :basic
            else
              :none
            end

    # create the headers hash
    @headers = {}
    conf.elements.each do |elem|
        elem.keys.each do |key|
          @headers[key] = elem[key]
        end
    end
  end

  def start
    super
  end

  def shutdown
    super
  end

  def format_url
     @endpoint_url
  end

  def set_body(req, tag, record)
    if @include_tag
      record['tag'] = tag
    end
    if @include_timestamp
      record['timestamp'] = Time.now.to_i
    end 
    if @serializer == :json
      set_json_body(req, record)
    else
      req.set_form_data(record)
    end
     req
  end

  def set_header(req)
    @headers.each do |key, value|
      req[key] = value
    end
  end

  def set_json_body(req, data)
    req.body = Yajl.dump(data)
    req['Content-Type'] = 'application/json'
  end

  def create_request(tag, time, record)
    url = format_url()
    uri = URI.parse(url)
    req = Net::HTTP.const_get(@http_method.to_s.capitalize).new(uri.path)
    set_body(req, tag, record)
    set_header(req)
    return req, uri
  end

  def send_request(req, uri, record)
    is_rate_limited = (@rate_limit_msec != 0 and not @last_request_time.nil?)
    if is_rate_limited and ((Time.now.to_f - @last_request_time) * 1000.0 < @rate_limit_msec)
      $log.info('Dropped request due to rate limiting')
      return
    end
    
    res = nil
    begin
      if @auth and @auth == :basic
        req.basic_auth(@username, @password)
      end
      @last_request_time = Time.now.to_f
      if @use_proxy
        https = Net::HTTP.new(uri.host, uri.port, @proxy_addr, @proxy_port)
      else
        https = Net::HTTP.new(uri.host, uri.port)
      end
      https.use_ssl = @use_ssl
      https.ca_file = OpenSSL::X509::DEFAULT_CERT_FILE 
      https.verify_mode = OpenSSL::SSL::VERIFY_NONE
      res = https.start {|http| http.request(req) }
    rescue IOError, EOFError, SystemCallError
      $log.warn "HTTPS Output :: Net::HTTP.#{req.method.capitalize} raises exception: #{$!.class}, '#{$!.message}'"
    end
    unless res and res.is_a?(Net::HTTPSuccess)
      res_summary = if res
                      "#{res.code} #{res.message} #{res.body}"
                    else
                      "res=nil"
                    end
      $log.warn "HTTPS Output :: failed to #{req.method} #{uri} (#{res_summary})"
      $log.warn "HTTPS Output :: record failed to send : #{record}"
    else 
      $log.info "HTTPS Output :: emitted record : #{record}"
    end
  end

  def handle_record(tag, time, record)
    req, uri = create_request(tag, time, record)
    send_request(req, uri, record)
  end

  def emit(tag, es, chain)
    es.each do |time, record|
      handle_record(tag, time, record)
    end
    chain.next
  end
end
