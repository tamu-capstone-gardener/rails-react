require Rails.root.join("app/services/mqtt_listener")

Thread.new { MqttListener.start }
