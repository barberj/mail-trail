require 'sinatra'
require 'json'
require 'remote_syslog_logger'
require 'mail'
require 'aws-sdk'

$logger = RemoteSyslogLogger.new('logs4.papertrailapp.com', 54460)
$logger.formatter = proc do |severity, datetime, progname, msg|
  "#{severity} #{msg}"
end

class App < Sinatra::Base
  post '/' do
    message = Mail.new(params['email']) do
      to 'barber.justin+stackmail@gmail.com'
      message_id nil
    end
    #from_address = params['from']
    #subject = params['subject']
    #html = params['html']
    #text = params['text']

    #$logger.info("request.POST #{request.POST.keys}")
    #raw_orig_message = request.body.read
    #s3_upload('stackmail', 'raw_orig_message', body: raw_orig_message)
    #s3_upload('stackmail', 'sendgrid_email', body: params['email'])

    #orig_message = Mail.new(raw_orig_message)
    #$logger.info("Original Message #{orig_message.message_id}")

    #message = Mail.new do
    #  from     from_address
    #  to       'barber.justin+stackmail@gmail.com'
    #  subject  subject
    #  headers  {}
    #end

    #orig_message.attachments.each do |attachment|
    #  $logger.info("Adding attachment #{attachment.filename}")
    #  message.add_file(
    #    filename: attachment.filename,
    #    content: attachment.body.to_s
    #  )
    #end

    #orig_message.attachments.zip(message.attachments).each do |orig, msg|
    #  msg.header = orig.header

    #  $logger.info("substituing inline #{orig.url} for #{msg.url}")
    #  html = html.gsub(orig.url, msg.url)
    #end

    #message.html_part do
    #  content_type "text/html; charset=UTF-8"
    #  body html
    #end

    #message.text_part do
    #  content_type "text/plain; charset=UTF-8"
    #  body text
    #end

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

def credentials
  @credentials ||= Aws::Credentials.new(ENV.fetch('AWS_ID'), ENV.fetch('AWS_SECRET'))
end

def s3_client
  @s3_client ||= Aws::S3::Client.new(
    credentials: credentials,
    region: 'us-east-1'
  )
end

def s3
  @s3 ||= Aws::S3::Resource.new(client: s3_client)
end

def get_bucket(name)
  s3.bucket(name).tap { |bucket| bucket.exists? || bucket.create }
end

def s3_upload(bucket_name, name, body:, **options)
  get_bucket(bucket_name).object(name).
    put(options.merge(body: body))
end

def s3_download(bucket_name, name)
  buffer = StringIO.new
  get_bucket(bucket_name).object(name).
    get(options.merge(response_target: buffer))
  buffer.read
end
