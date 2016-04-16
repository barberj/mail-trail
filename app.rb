require 'sinatra'
require 'json'
require 'remote_syslog_logger'

$logger = RemoteSyslogLogger.new('logs4.papertrailapp.com', 54460)
$logger.formatter = proc do |severity, datetime, progname, msg|
  "#{severity} #{msg}"
end


 ["headers", "attachment2", "dkim", "content-ids", "to", "cc", "html", "from", "text", "sender_ip", "attachment1", "envelope", "attachments", "subject", "attachment-info", "charsets", "SPF"]

class App < Sinatra::Base
  post '/' do
    email = request.body.read
    $logger.info(params.keys)
    email = params["email"]
    cc = params["cc"]
    to = params["to"]
    from = params["from"]
    subject = params["subject"]
    $logger.info(params["attachments"])
    $logger.info(params["attachment-info"])
    status 200
    "Ok"
  end
end
