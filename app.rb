require 'sinatra'
require 'json'
require 'remote_syslog_logger'
require 'mail'

$logger = RemoteSyslogLogger.new('logs4.papertrailapp.com', 54460)
$logger.formatter = proc do |severity, datetime, progname, msg|
  "#{severity} #{msg}"
end

 ["headers", "attachment2", "dkim", "content-ids", "to", "cc", "html", "from", "text", "sender_ip", "attachment1", "envelope", "attachments", "subject", "attachment-info", "charsets", "SPF"]

class App < Sinatra::Base
  post '/' do
    from_address = params['from']
    subject = params['subject']
    body = request.body.read

    message = Mail.new do
      from     from_address
      to       'barber.justin+stackmail@gmail.com'
      subject  subject
      headers  {}
      body     body
    end

    message.delivery_method(:smtp, {
      address: ENV.fetch("SMTP_ADDR"),
      port: ENV.fetch("SMTP_PORT"),
      user_name: ENV.fetch("SMTP_USER"),
      password: ENV.fetch("SMTP_PASSWORD"),
      enable_starttls_auto: true,
      authentication: ENV.fetch('SMTP_AUTH')
    })

    message.deliver
    $logger.info("Sent message #{message.message_id}")

    status 200
    "Ok"
  end
end
