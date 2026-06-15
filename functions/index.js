const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { onObjectFinalized } = require("firebase-functions/v2/storage");
const admin = require("firebase-admin");
const vision = require('@google-cloud/vision');

admin.initializeApp();

// ১. নোটিফিকেশন লজিক (আপনার পুরাতন কোড অক্ষত আছে)
exports.sendChatNotification = onDocumentCreated("chats/{chatId}/messages/{messageId}", async (event) => {
    const data = event.data.data();
    
    const receiverId = data.receiverId; 
    const messageText = data.message; 
    const senderName = data.senderName || "New Message"; 

    const receiverDoc = await admin.firestore().collection("users").doc(receiverId).get();
    
    if (!receiverDoc.exists) {
        console.log("Receiver not found");
        return null;
    }
    
    const fcmToken = receiverDoc.data().fcmToken;

    if (fcmToken) {
        const message = {
            notification: {
                title: senderName,
                body: messageText,
            },
            token: fcmToken,
        };

        try {
            await admin.messaging().send(message);
            console.log("Notification sent successfully to:", receiverId);
        } catch (error) {
            console.error("Error sending notification:", error);
        }
    }
    return null;
});

// ২. মডারেশন লজিক (নতুন ফিচার - অটোমেটিক ছবি চেক করবে)
const client = new vision.ImageAnnotatorClient();

exports.moderateImage = onObjectFinalized(async (event) => {
    const object = event.data;
    const filePath = object.name;
    const bucket = admin.storage().bucket(object.bucket);

    // শুধুমাত্র ছবির ক্ষেত্রে কাজ করবে
    if (!object.contentType.startsWith('image/')) {
        return null;
    }

    const [result] = await client.safeSearchDetection(`gs://${object.bucket}/${filePath}`);
    const detections = result.safeSearchAnnotation;

    // যদি এডাল্ট বা আপত্তিকর কন্টেন্ট পায়
    if (detections.adult === 'VERY_LIKELY' || detections.racy === 'VERY_LIKELY') {
        console.log(`Inappropriate content detected. Deleting: ${filePath}`);
        return bucket.file(filePath).delete();
    }
    
    return null;
});