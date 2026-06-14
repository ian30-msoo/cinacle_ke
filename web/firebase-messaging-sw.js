importScripts("https://www.gstatic.com/firebasejs/10.7.0/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/10.7.0/firebase-messaging-compat.js");

firebase.initializeApp({
  apiKey: "AIzaSyAEETrUz-lrcplJlQ0YuuufTktAMamE3ww",
  authDomain: "cenacle-link-app.firebaseapp.com",
  projectId: "cenacle-link-app",
  storageBucket: "cenacle-link-app.firebasestorage.app",
  messagingSenderId: "125218567647",
  appId: "1:125218567647:web:5ec655d9bd0efc0758006a",
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  console.log("Background message received:", payload);
  self.registration.showNotification(payload.notification.title, {
    body: payload.notification.body,
    icon: "/icons/Icon-192.png",
  });
});