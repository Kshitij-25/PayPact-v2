importScripts("https://www.gstatic.com/firebasejs/10.7.0/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/10.7.0/firebase-messaging-compat.js");

firebase.initializeApp({
    apiKey: "AIzaSyB4fsgbSrFNR0JstFXvd-aK_vyX742FKOM",
    authDomain: "paypact-fec8e.firebaseapp.com",
    projectId: "paypact-fec8e",
    storageBucket: "paypact-fec8e.firebasestorage.app",
    messagingSenderId: "531387933797",
    appId: "1:531387933797:web:608c22793e00144387d28c",
    measurementId: "G-HZ4E0L5KT6"
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage(function (payload) {
    console.log("Received background message ", payload);

    self.registration.showNotification(payload.notification.title, {
        body: payload.notification.body,
        icon: "/icons/Icon-192.png"
    });
});