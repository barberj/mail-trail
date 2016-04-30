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
    html = params['html']
    text = params['text']

    $logger.info('Payload')
    $logger.info(request.payload)

    $logger.info('Keys')
    $logger.info(params.keys)
    $logger.info('Attachments')
    $logger.info(params['attachments'])
    $logger.info('Attachment-Info')
    $logger.info(params['attachment-info'])
    $logger.info('Content-Ids')
    $logger.info(params['content-ids'])
    $logger.info('Envelope')
    $logger.info(params['envelope'])
    $logger.info(params)

    message = Mail.new do
      from     from_address
      to       'barber.justin+stackmail@gmail.com'
      subject  subject
      headers  {}
    end

    message.html_part do
      content_type "text/html; charset=UTF-8"
      body html
    end

    message.text_part do
      content_type "text/plain; charset=UTF-8"
      body text
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
