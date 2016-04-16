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
    email = params[:email]
    cc = params[:cc]
    to = params[:to]
    from = params[:from]
    subject = params[:subject]
    $logger.info(email)
    $logger.info(params)
    status 200
    "Ok"
  end
end
