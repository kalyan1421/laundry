/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

const {onRequest} = require("firebase-functions/v2/https");
const {onDocumentCreated} = require("firebase-functions/v2/firestore");
const {initializeApp} = require("firebase-admin/app");
const {getFirestore} = require("firebase-admin/firestore");
const {getMessaging} = require("firebase-admin/messaging");

// Create and deploy your first functions
// https://firebase.google.com/docs/functions/get-started

// exports.helloWorld = onRequest((request, response) => {
//   logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });

initializeApp();

// Cloud Function to process FCM notifications
exports.processFcmNotifications = onDocumentCreated(
    "fcm_notifications/{notificationId}",
    async (event) => {
      const notificationData = event.data.data();
      const notificationId = event.params.notificationId;

      console.log(
          `Processing FCM notification: ${notificationId}`,
          notificationData,
      );

      try {
        const {token, title, body, data, priority} = notificationData;

        if (!token || !title || !body) {
          console.error("Missing required fields for FCM notification");
          await event.data.ref.update({
            status: "failed",
            error: "Missing required fields",
          });
          return;
        }

        // Prepare FCM message
        const message = {
          token: token,
          notification: {
            title: title,
            body: body,
          },
          data: data || {},
          android: {
            priority: priority === "high" ? "high" : "normal",
            notification: {
              channelId: "laundry_channel",
              priority: priority === "high" ? "high" : "default",
              defaultSound: true,
              defaultVibrateTimings: true,
            },
          },
          apns: {
            payload: {
              aps: {
                alert: {
                  title: title,
                  body: body,
                },
                sound: "default",
                badge: 1,
              },
            },
          },
        };

        // Send the notification
        const response = await getMessaging().send(message);
        console.log("FCM notification sent successfully:", response);

        // Update status to sent
        await event.data.ref.update({
          status: "sent",
          sentAt: new Date(),
          messageId: response,
        });
      } catch (error) {
        console.error("Error sending FCM notification:", error);
        await event.data.ref.update({
          status: "failed",
          error: error.message,
          failedAt: new Date(),
        });
      }
     },
);

// Cloud Function to send notification when a new order is created
exports.sendOrderNotificationToAdmin = onDocumentCreated(
    "orders/{orderId}",
    async (event) => {
      const orderData = event.data.data();
      const orderId = event.params.orderId;

      console.log(`New order created: ${orderId}`, orderData);

      try {
        // Get all active admin tokens
        const adminTokens = await getAdminTokens();

        if (adminTokens.length === 0) {
          console.log("No admin tokens found for notification");
          return null;
        }

        console.log(`Found ${adminTokens.length} admin tokens`);

        // Prepare notification payload
        const payload = {
          notification: {
            title: "New Order Received",
            body: `A new order #${orderId} has been placed and ` +
              `needs assignment.`,
          },
          data: {
            type: "new_order",
            orderId: orderId,
            route: "/admin/orders",
          },
        };

        // Send notifications to all admin tokens
        const promises = adminTokens.map((token) => {
          return getMessaging().send({
            token: token,
            ...payload,
          });
        });

        await Promise.all(promises);

        console.log(`Notifications sent to ${adminTokens.length} admins`);

        // Update order to mark notification sent
        await getFirestore()
            .collection("orders")
            .doc(orderId)
            .update({notificationSentToAdmin: true});

        return null;
      } catch (error) {
        console.error("Error sending admin notification:", error);
        return null;
      }
    },
);

// Cloud Function to send assignment notification to delivery person
exports.sendAssignmentNotification = onRequest(async (req, res) => {
  try {
    const {orderId, deliveryPersonId, customerName, pickupAddress} = req.body;

    if (!orderId || !deliveryPersonId || !customerName || !pickupAddress) {
      res.status(400).json({
        error: "Missing required fields: orderId, deliveryPersonId, " +
          "customerName, pickupAddress",
      });
      return;
    }

    // Get delivery person's token
    const deliveryDoc = await getFirestore()
        .collection("delivery")
        .doc(deliveryPersonId)
        .get();

    if (!deliveryDoc.exists) {
      res.status(404).json({error: "Delivery person not found"});
      return;
    }

    const deliveryData = deliveryDoc.data();
    const token = deliveryData.fcmToken;

    if (!token) {
      res.status(404).json({error: "Delivery person FCM token not found"});
      return;
    }

    // Send notification
    const payload = {
      token: token,
      notification: {
        title: "New Order Assignment",
        body: `You have been assigned order #${orderId} for pickup ` +
          `from ${pickupAddress}`,
      },
      data: {
        type: "order_assignment",
        orderId: orderId,
        route: "/delivery/orders",
      },
    };

    await getMessaging().send(payload);

    // Update order to mark notification sent
    await getFirestore()
        .collection("orders")
        .doc(orderId)
        .update({notificationSentToDeliveryPerson: true});

    res.json({success: true, message: "Assignment notification sent"});
  } catch (error) {
    console.error("Error sending assignment notification:", error);
    res.status(500).json({error: error.message});
  }
});

// Cloud Function to send status update notification to customer
exports.sendStatusUpdateNotification = onRequest(async (req, res) => {
  try {
    const {orderId, customerId, status, statusMessage} = req.body;

    if (!orderId || !customerId || !status || !statusMessage) {
      res.status(400).json({
        error: "Missing required fields: orderId, customerId, " +
          "status, statusMessage",
      });
      return;
    }

    // Get customer's token
    const customerDoc = await getFirestore()
        .collection("customer")
        .doc(customerId)
        .get();

    if (!customerDoc.exists) {
      res.status(404).json({error: "Customer not found"});
      return;
    }

    const customerData = customerDoc.data();
    const token = customerData.fcmToken;

    if (!token) {
      res.status(404).json({error: "Customer FCM token not found"});
      return;
    }

    // Send notification
    const payload = {
      token: token,
      notification: {
        title: "Order Update",
        body: `Your order #${orderId} status: ${statusMessage}`,
      },
      data: {
        type: "status_update",
        orderId: orderId,
        status: status,
        route: "/orders/track",
      },
    };

    await getMessaging().send(payload);

    res.json({success: true, message: "Status update notification sent"});
  } catch (error) {
    console.error("Error sending status update notification:", error);
    res.status(500).json({error: error.message});
  }
});

/**
 * Helper function to get all admin tokens
 * @return {Promise<Array<string>>} Array of admin FCM tokens
 */
async function getAdminTokens() {
  try {
    const adminSnapshot = await getFirestore()
        .collection("admins")
        .where("isActive", "==", true)
        .get();

    const tokens = [];
    adminSnapshot.forEach((doc) => {
      const data = doc.data();
      if (data.fcmToken) {
        tokens.push(data.fcmToken);
      }
    });

    return tokens;
  } catch (error) {
    console.error("Error getting admin tokens:", error);
    return [];
  }
}

// Manual function to test notifications
exports.testNotification = onRequest(async (req, res) => {
  try {
    const adminTokens = await getAdminTokens();

    if (adminTokens.length === 0) {
      res.json({message: "No admin tokens found"});
      return;
    }

    const payload = {
      notification: {
        title: "Test Notification",
        body: "This is a test notification from Firebase Functions",
      },
      data: {
        type: "test",
        timestamp: new Date().toISOString(),
      },
    };

    const promises = adminTokens.map((token) => {
      return getMessaging().send({
        token: token,
        ...payload,
      });
    });

    await Promise.all(promises);

    res.json({
      success: true,
      message: `Test notifications sent to ${adminTokens.length} admins`,
      tokens: adminTokens.length,
    });
  } catch (error) {
    console.error("Error sending test notification:", error);
    res.status(500).json({error: error.message});
  }
});
