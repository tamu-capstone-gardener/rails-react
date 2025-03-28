import { application } from "controllers/application"
import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading"
import "@hotwired/turbo-rails"
eagerLoadControllersFrom("controllers", application)
import "controllers"
import "chartkick"
import "Chart.bundle"


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
  ).content;
  
  export const subscribe = async () => {
    const registration = await navigator.serviceWorker.ready;
  
    let subscription = await registration.pushManager.getSubscription();
  
    if (!subscription) {
      subscription = await registration.pushManager.subscribe({
        userVisibleOnly: true,
        applicationServerKey: vapidPublicKey,
      });
  
      if (!subscription) {
        console.error('Web push subscription failed');
      }
    }
  
    return subscription;
  };

  document.querySelectorAll('a').forEach(link => {
    link.addEventListener('mouseenter', () => {
      console.log('hovered:', link.href);
    });
    link.addEventListener('click', e => {
      console.log('clicked:', link.href);
    });
  });
  