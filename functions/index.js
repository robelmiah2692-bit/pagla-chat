const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");

admin.initializeApp();

exports.sendChatNotification = onDocumentCreated("chats/{chatId}/messages/{messageId}", async (event) => {
    // ইভেন্ট থেকে ডাটা নেওয়া হচ্ছে
    const data = event.data.data();
    
    // স্ক্রিনশট অনুযায়ী ডাটা ফিল্ডগুলো সেট করা হচ্ছে
    const receiverId = data.receiverId; 
    const messageText = data.message; // আপনার ডাটাবেসে ফিল্ডের নাম 'message'
    const senderName = data.senderName || "New Message"; // আপনার ডাটাবেসে ফিল্ডের নাম 'senderName'

    // রিসিভারের FCM টোকেন সংগ্রহ করা হচ্ছে
    const receiverDoc = await admin.firestore().collection("users").doc(receiverId).get();
    
    if (!receiverDoc.exists) {
        console.log("Receiver not found");
        return null;
    }
    
    const fcmToken = receiverDoc.data().fcmToken;

    if (fcmToken) {
        const message = {
            notification: {
                title: senderName, // এখন এটি ডাটাবেসের 'senderName' দেখাবে
                body: messageText, // এখন এটি ডাটাবেসের 'message' দেখাবে
            },
            token: fcmToken,
        };

        // নোটিফিকেশন পাঠানো
        try {
            await admin.messaging().send(message);
            console.log("Notification sent successfully to:", receiverId);
        } catch (error) {
            console.error("Error sending notification:", error);
        }
    }
    return null;
});