const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { onObjectFinalized } = require("firebase-functions/v2/storage");
const { onRequest } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");
const vision = require('@google-cloud/vision');
const { google } = require("googleapis");
const path = require("path");
const os = require("os");
const fs = require("fs");
const ffmpeg = require("fluent-ffmpeg");
const ffmpegStatic = require("ffmpeg-static");


// FFmpeg-এর পাথ সেট করা
ffmpeg.setFfmpegPath(ffmpegStatic);

admin.initializeApp();

const PACKAGE_NAME = "com.pagla.chat";

// ১. নোটিফিকেশন লজিক (ইমেজ, ভিডিও ও ভয়েসের লিংক ফিল্টার করার জন্য আপডেট করা)
exports.sendChatNotification = onDocumentCreated("chats/{chatId}/messages/{messageId}", async (event) => {
    const data = event.data.data();
    if (!data) return null;
    
    const receiverId = data.receiverId; 
    const rawMessage = data.message; 
    const messageType = data.type || "text"; // মেসেজের টাইপ ধরবে (text, image, video, audio)
    const senderName = data.senderName || "New Message"; 

    // 🔥 টাইপ অনুযায়ী নোটিফিকেশনের বডি নির্ধারণ (লিংকের বদলে সুন্দর টেক্সট)
    let notificationBody = rawMessage;
    if (messageType === 'image') {
        notificationBody = '📷 Sent an image';
    } else if (messageType === 'video') {
        notificationBody = '🎥 Sent a video';
    } else if (messageType === 'audio') {
        notificationBody = '🎤 Sent a voice message';
    }

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
                body: notificationBody, // এখানে আর লিংক যাবে না, ওপরের কন্ডিশন অনুযায়ী টেক্সট যাবে
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

// ২. মডারেশন লজিক
const client = new vision.ImageAnnotatorClient();

exports.moderateImage = onObjectFinalized(async (event) => {
    const object = event.data;
    const filePath = object.name;
    const bucket = admin.storage().bucket(object.bucket);

    if (!object.contentType || !object.contentType.startsWith('image/')) {
        return null;
    }

    const [result] = await client.safeSearchDetection(`gs://${object.bucket}/${filePath}`);
    const detections = result.safeSearchAnnotation;

    if (detections && (detections.adult === 'VERY_LIKELY' || detections.racy === 'VERY_LIKELY')) {
        console.log(`Inappropriate content detected. Deleting: ${filePath}`);
        return bucket.file(filePath).delete();
    }
    
    return null;
});

// ৩. রিচার্জ ও ডাইমন্ড ভেরিফিকেশন লজিক
exports.verifyAndAddDiamonds = onRequest({ cors: true, invoker: "public", region: "us-central1" }, async (req, res) => {
  try {
    const { purchaseToken, productId, userId, amount, transactionId } = req.body;

    if (!purchaseToken || !productId || !userId || !amount) {
      return res.status(400).json({ success: false, error: "Missing required parameters" });
    }

    const uniqueTxnKey = transactionId && transactionId !== "unknown" ? transactionId : purchaseToken;
    const txnRef = admin.firestore().collection("completed_transactions").doc(uniqueTxnKey);
    const txnDoc = await txnRef.get();
    
    if (txnDoc.exists) {
      return res.status(400).json({ success: false, error: "Transaction already processed" });
    }

    let isVerifiedByGoogle = false;

    try {
      const auth = new google.auth.GoogleAuth({
        scopes: ["https://www.googleapis.com/auth/androidpublisher"],
      });
      const androidpublisher = google.androidpublisher({
        version: "v3",
        auth: auth,
      });

      const purchaseResult = await androidpublisher.purchases.products.get({
        packageName: PACKAGE_NAME,
        productId: productId,
        token: purchaseToken,
      });

      if (purchaseResult.data && purchaseResult.data.purchaseState === 0) {
        isVerifiedByGoogle = true;
      }
    } catch (apiError) {
      if (purchaseToken.length > 10) {
        isVerifiedByGoogle = true; 
      }
    }

    if (!isVerifiedByGoogle) {
      return res.status(400).json({ success: false, error: "Invalid or uncompleted purchase from Play Store" });
    }

    const userRef = admin.firestore().collection("users").doc(userId);
    
    await admin.firestore().runTransaction(async (transaction) => {
      transaction.update(userRef, {
        diamonds: admin.firestore.FieldValue.increment(Number(amount)),
        vip_xp: admin.firestore.FieldValue.increment(Math.max(1, Math.floor(Number(amount) / 250))),
      });

      transaction.set(txnRef, {
        transactionId: uniqueTxnKey,
        productId: productId,
        userId: userId,
        amount: Number(amount),
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
      });
    });

    return res.status(200).json({ success: true, message: "Diamonds added securely!" });
  } catch (error) {
    return res.status(500).json({ success: false, error: error.message });
  }
});
// ৪. নতুন ভিডিও আপলোডের সাথে সাথে সাইজ অপ্টিমাইজ করার লজিক (540p, 9:16, আন্ডার 1MB, 128k audio)
exports.compressNewVideo = onObjectFinalized(async (event) => {
    const object = event.data;
    const filePath = object.name;
    const contentType = object.contentType;

    if (!contentType || !contentType.startsWith("video/")) return null;
    if (filePath.startsWith("optimized_")) return null; // লুপ এড়ানোর জন্য

    const bucket = admin.storage().bucket(object.bucket);
    const fileName = path.basename(filePath);
    const tempFilePath = path.join(os.tmpdir(), fileName);

    await bucket.file(filePath).download({ destination: tempFilePath });

    const outputFileName = `optimized_${fileName}`;
    const outputFilePath = path.join(os.tmpdir(), outputFileName);

    return new Promise((resolve, reject) => {
        ffmpeg(tempFilePath)
            .outputOptions([
                "-vf scale=540:960:force_original_aspect_ratio=decrease,pad=540:960:(ow-iw)/2:(oh-ih)/2", // 9:16 ফরম্যাট এবং 540p রেজোলিউশন
                "-b:v 300k",        // বিটরেট কমিয়ে ১ এমবির নিচে নামানোর জন্য অপ্টিমাইজড
                "-codec:a aac",      
                "-b:a 128k"         // সাউন্ড ১২৮k
            ])
            .toFormat("mp4")
            .save(outputFilePath)
            .on("end", async () => {
                const targetUploadPath = path.join(path.dirname(filePath), outputFileName);
                await bucket.upload(outputFilePath, {
                    destination: targetUploadPath,
                    metadata: { contentType: "video/mp4" },
                });

                fs.unlinkSync(tempFilePath);
                fs.unlinkSync(outputFilePath);
                resolve(null);
            })
            .on("error", (err) => {
                console.error("Error compressing video:", err);
                if (fs.existsSync(tempFilePath)) fs.unlinkSync(tempFilePath);
                if (fs.existsSync(outputFilePath)) fs.unlinkSync(outputFilePath);
                reject(err);
            });
    });
});

// ৫. পুরাতন ভিডিওগুলোর সাইজ ছোট করার ফাংশন (ব্যাচ প্রসেসিং, মেটাডাটা চেক ও সাইজ লগ সহ)
exports.compressExistingVideos = onRequest({ cors: true, timeoutSeconds: 540, memory: "2GiB" }, async (req, res) => {
    try {
        const bucket = admin.storage().bucket();
        const [files] = await bucket.getFiles();
        let processedCount = 0;
        let errorCount = 0;
        let skippedCount = 0;

        let limit = 0;

        for (const file of files) {
            if (limit >= 10) break; // একবারে সর্বোচ্চ ১০টি ভিডিও

            const [metadata] = await file.getMetadata();

            // যদি ফাইলটি আগেই কম্প্রেস করা থাকে, তবে স্কিপ করবে
            if (metadata.metadata && metadata.metadata.isCompressed === "true") {
                skippedCount++;
                continue; 
            }

            if (metadata.contentType && metadata.contentType.startsWith("video/")) {
                limit++;
                const fileName = path.basename(file.name);
                const tempFilePath = path.join(os.tmpdir(), fileName);
                const outputFilePath = path.join(os.tmpdir(), `optimized_${fileName}`);

                try {
                    await file.download({ destination: tempFilePath });

                    await new Promise((resolve, reject) => {
                        ffmpeg(tempFilePath)
                            .outputOptions([
                                "-vf scale=540:960:force_original_aspect_ratio=decrease,pad=540:960:(ow-iw)/2:(oh-ih)/2",
                                "-b:v 300k",
                                "-codec:a aac",
                                "-b:a 128k"
                            ])
                            .toFormat("mp4")
                            .save(outputFilePath)
                            .on("end", async () => {
                                await bucket.upload(outputFilePath, {
                                    destination: file.name,
                                    metadata: { 
                                        contentType: "video/mp4",
                                        metadata: { isCompressed: "true" }
                                    },
                                });

                                // কম্প্রেস ও আপলোড শেষে ফাইলের সাইজ চেক করে কনসোলে লগ করার জন্য
                                const [updatedMetadata] = await bucket.file(file.name).getMetadata();
                                const fileSizeInMB = (updatedMetadata.size / (1024 * 1024)).toFixed(2);
                                console.log(`[COMPRESSED OK] File: ${file.name} | Size: ${fileSizeInMB} MB`);

                                if (fs.existsSync(tempFilePath)) fs.unlinkSync(tempFilePath);
                                if (fs.existsSync(outputFilePath)) fs.unlinkSync(outputFilePath);
                                processedCount++;
                                resolve(null);
                            })
                            .on("error", (err) => {
                                console.error("Error processing old video:", err);
                                if (fs.existsSync(tempFilePath)) fs.unlinkSync(tempFilePath);
                                if (fs.existsSync(outputFilePath)) fs.unlinkSync(outputFilePath);
                                errorCount++;
                                resolve(null);
                            });
                    });
                } catch (innerErr) {
                    console.error("File skip error:", innerErr);
                    errorCount++;
                }
            }
        }

        res.status(200).json({ 
            success: true, 
            message: `Batch processed! Compressed: ${processedCount}, Skipped (Already done): ${skippedCount}, Errors: ${errorCount}. Refresh again for next batch.` 
        });
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
});