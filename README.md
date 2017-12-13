## Fluent::Plugin::HTTPSClient

Output plugin for [Fluentd](http://fluentd.org), for sending records to an HTTP or HTTPS endpoint, with SSL, Proxy,
 and Header implementation.
 
## Configuration Guide

    <match *>
      type              https_client           
      endpoint_url      # endpoint_url 
      http_method       # get / post / put / delete defaults to post
      serializer        # json / form defaults to form
      include_timestamp # true / false defaults to false
      rate_limit_msec   # limit the rate in ms, defaults to 10 ms
      auth              # basic / none
      use_ssl           # true / false
      proxy_addr        # proxy url
      proxy_port        # proxy port
      username          # user name if auth is basic
      password          # password if auth is basic
      <header>          # HTTP headers (see examples below)
        Accept          application/json
        auth_token      my_secret
      </header>
    </match>
    
    
 ### Use Cases
 * send records to HTTP endpoints
 * send records to HTTPS endpoints
 * send events through proxy
 * send events by setting custom headers (header-based authentication, etc)
 

### Credits
* Majority of the code is cloned from [fluent-plugin-out-http](https://github.com/ento/fluent-plugin-out-http)
* SSL implementation from [fluent-plugin-out-https](https://github.com/kazunori279/fluent-plugin-out-https)

### Exception Handling
* For retries in case of exceptions, use
 [fluent-plugin-bufferize](https://github.com/kazegusuri/fluent-plugin-bufferize) as a wrapper.



