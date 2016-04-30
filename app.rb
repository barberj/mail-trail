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

    raw_orig_message = request.body.read

    $logger.info("*"*50)
    $logger.info(raw_orig_message)
    $logger.info("*"*50)

    orig_message = Mail.new(raw_orig_message)
    $logger.info("Original Message #{message.message_id}")

    message = Mail.new do
      from     from_address
      to       'barber.justin+stackmail@gmail.com'
      subject  subject
      headers  {}
    end

    orig_message.attachments.each do |attachment|
      $logger.info("Adding attachment #{attachment.filename}")
      message.add_file(
        filename: attachment.filename,
        content: attachment.body.to_s
      )
    end

    orig_message.attachments.zip(message.attachments).each do |orig, msg|
      msg.header = orig.header

      $logger.info("substituing inline #{orig.url} for #{msg.url}")
      html = html.gsub(orig.url, msg.url)
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
