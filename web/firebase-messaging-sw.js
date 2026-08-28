// Handles push notifications that arrive while no tab for this app is
// focused (background/closed-tab case) — the browser runs this service
// worker independently of the Flutter app and shows the notification
// itself. Foreground-tab messages (app open and focused) are handled in
// Dart instead, via FirebaseMessaging.onMessage in push_notification_service.dart.
//
// Config below matches lib/firebase_options.dart's `web` FirebaseOptions —
// keep both in sync if the Firebase project's web app config ever changes.
importScripts('https://www.gstatic.com/firebasejs/10.7.1/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.7.1/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyBrFLjeZOhFROx3Ou_5DR4PQoA3hC5goiE',
  authDomain: 'ts-mincab.firebaseapp.com',
  projectId: 'ts-mincab',
  storageBucket: 'ts-mincab.firebasestorage.app',
  messagingSenderId: '873160171304',
  appId: '1:873160171304:web:28c05e1b9ea0bc076ffa1d',
});

firebase.messaging();
