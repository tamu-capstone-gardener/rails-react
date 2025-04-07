Sidekiq.configure_server do |config|
    config.server_middleware do |chain|
      chain.remove Sidekiq::JobRetry
    end
  end
