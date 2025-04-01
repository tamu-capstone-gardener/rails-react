// app/javascript/channels/index.js
import { createConsumer } from "@rails/actioncable"
import "channels/consumer"
import "channels/notifications_channel"

// Initialize Action Cable consumer
window.App ||= {}
window.App.cable = createConsumer()


