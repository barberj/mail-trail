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
      to ENV.fetch('DEMO_ADRR')
      message_id "#{SecureRandom.hex}@stackmail.simpleapp.io"
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
