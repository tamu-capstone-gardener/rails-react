import { application } from "controllers/application"
import { lazyLoadControllersFrom } from "@hotwired/stimulus-loading"
import "@hotwired/turbo-rails"
import "controllers"
import "chartkick"
import "Chart.bundle"
import "channels"

lazyLoadControllersFrom("controllers", application)

const registerServiceWorker = async () => {
  if (navigator.serviceWorker) {
    try {
      await navigator.serviceWorker.register('/serviceworker.js');
      console.log('Service worker registered!');
    } catch (error) {
      console.error('Error registering service worker: ', error);
    }
  }
};

registerServiceWorker();

export const checkPermission = async () => {
  switch (Notification.permission) {
    case 'granted':
      console.log('Permission to receive notifications has been granted');
      break;
    case 'denied':
      console.log('Permission to receive notifications has been denied');
      break;
    default:
      const permission = await Notification.requestPermission();
      console.log(`Permission to receive notifications has been ${permission}`);
      break;
  }
};

const vapidPublicKey = document.querySelector(
  'meta[name="vapid-public-key"]',
)?.content;

export const subscribe = async () => {
  const registration = await navigator.serviceWorker.ready;

  let subscription = await registration.pushManager.getSubscription();

  if (!subscription) {
    subscription = await registration.pushManager.subscribe({
      userVisibleOnly: true,
      applicationServerKey: urlBase64ToUint8Array(vapidPublicKey),
    });

    if (!subscription) {
      console.error('Web push subscription failed');
    }
  }

  return subscription;
};

// Helper function to convert VAPID public key to Uint8Array
function urlBase64ToUint8Array(base64String) {
  const padding = '='.repeat((4 - base64String.length % 4) % 4);
  const base64 = (base64String + padding)
    .replace(/\-/g, '+')
    .replace(/_/g, '/');

  const rawData = window.atob(base64);
  const outputArray = new Uint8Array(rawData.length);

  for (let i = 0; i < rawData.length; ++i) {
    outputArray[i] = rawData.charCodeAt(i);
  }
  return outputArray;
}
