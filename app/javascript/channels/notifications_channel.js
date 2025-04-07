// // app/javascript/channels/notifications_channel.js
// import consumer from "channels/consumer"
// import { checkPermission } from "../application"

// // Request notification permission when the channel is created
// const requestNotificationPermission = async () => {
//   try {
//     await checkPermission()
//   } catch (error) {
//     console.error("Error requesting notification permission:", error)
//   }
// }

// requestNotificationPermission()

// consumer.subscriptions.create("NotificationsChannel", {
//   connected() {
//     console.log("Connected to notifications channel")
//   },

//   disconnected() {
//     console.log("Disconnected from notifications channel")
//   },

//   received(data) {
//     console.log("Push notification received:", data)

//     // Show browser notification if permission is granted
//     if (Notification.permission === "granted") {
//       new Notification(data.title, {
//         body: `${data.message} (${data.value}${data.unit})`,
//         tag: data.timestamp,
//         icon: "/favicon.ico"
//       })
//     }
//   }
// })
