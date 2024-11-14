importScripts("https://www.gstatic.com/firebasejs/11.0.1/firebase-app.js");
importScripts("https://www.gstatic.com/firebasejs/11.0.1/firebase-messaging.js");

firebase.initializeApp({
    apiKey: "AIzaSyAZhaJ7KtJsLc63qFhVd4s2xYuvGHlSmFk",
    authDomain: "efood-58b8a.firebaseapp.com",
    projectId: "efood-58b8a",
    storageBucket: "efood-58b8a.firebasestorage.app",
    messagingSenderId: "435964737383",
    appId: "1:435964737383:web:0271fbb6cfd0f71daca1c2",
    measurementId: "G-WX77NRZTXV",
    databaseURL: "...",
});

const messaging = firebase.messaging();

// Optional:
messaging.onBackgroundMessage((message) => {
});
