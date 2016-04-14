require 'sinatra'
require 'json'
require 'remote_syslog_logger'

$logger = RemoteSyslogLogger.new('logs4.papertrailapp.com', 54460)
$logger.formatter = proc do |severity, datetime, progname, msg|
  "#{severity} #{msg}"
end

class App < Sinatra::Base
  post '/' do
    email = request.body.read
    $logger.info(params.keys)
    #$logger.info(email)
    status 200
    "Ok"
  end
end
