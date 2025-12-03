/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

const {onRequest} = require("firebase-functions/v2/https");
const {
  onDocumentCreated,
  onDocumentUpdated,
} = require("firebase-functions/v2/firestore");
const {onSchedule} = require("firebase-functions/v2/scheduler");
const {initializeApp} = require("firebase-admin/app");
const {
  FieldValue,
  getFirestore,
  Timestamp,
} = require("firebase-admin/firestore");
const {getMessaging} = require("firebase-admin/messaging");

// Create and deploy your first functions
// https://firebase.google.com/docs/functions/get-started

// exports.helloWorld = onRequest((request, response) => {
//   logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });

initializeApp();

/**
 * Driver search and assignment logic
 * ---------------------------------
 * startDriverSearch      -> trigger when a new order is created
 * retryDriverSearch      -> trigger when assignmentStatus is reset to searching
 * checkExpiredOffers     -> scheduled cleanup for ignored offers
 */
exports.startDriverSearch = onDocumentCreated(
    "orders/{orderId}",
    async (event) => {
      const orderId = event.params.orderId;
      const orderData = event.data.data();

      console.log(`🚀 NEW ORDER CREATED: ${orderId}`);
      console.log(`📋 Order status: ${orderData?.status}`);
      console.log(`📋 Assignment status: ${orderData?.assignmentStatus}`);

      if (!orderData) {
        console.log("❌ No order data found");
        return null;
      }

      // Only start search for brand new orders
      const status = orderData.status?.toString().toLowerCase();
      if (status !== "pending" && status !== "new") {
        console.log(`⏭️ Skipping - status is ${status}, not pending/new`);
        return null;
      }

      console.log("✅ Starting driver search for order:", orderId);
      return assignToNearestDriver(orderId, {
        ...orderData,
        assignmentStatus: orderData.assignmentStatus ?? "searching",
      });
    },
);

exports.retryDriverSearch = onDocumentUpdated(
    "orders/{orderId}",
    async (event) => {
      const newData = event.data.after.data();
      const oldData = event.data.before.data();

      if (!newData || !oldData) return null;

      const becameSearching = newData.assignmentStatus === "searching" &&
        oldData.assignmentStatus !== "searching";

      if (!becameSearching) return null;

      return assignToNearestDriver(event.params.orderId, newData);
    },
);

/**
 * PHASE 2: Updated for broadcast system
 * Checks for expired broadcast offers (20 second timeout)
 * If all drivers ignored, marks all as rejected and retries search
 */
exports.checkExpiredOffers = onSchedule("every 1 minutes", async () => {
  const db = getFirestore();
  const now = Timestamp.now();

  // Check for expired BROADCAST offers
  const broadcastOrders = await db.collection("orders")
      .where("assignmentStatus", "==", "broadcasting")
      .get();

  // Also check legacy "offered" status for backward compatibility
  const legacyOrders = await db.collection("orders")
      .where("assignmentStatus", "==", "offered")
      .get();

  const allStaleOrders = [...broadcastOrders.docs, ...legacyOrders.docs];

  if (allStaleOrders.length === 0) return null;

  const batch = db.batch();

  allStaleOrders.forEach((doc) => {
    const data = doc.data();
    const timeout = data.assignmentTimeout;

    if (!timeout || typeof timeout.toMillis !== "function") return;

    // Check if offer has expired
    if (now.toMillis() < timeout.toMillis()) return;

    // BROADCAST: Mark all offered drivers as rejected
    const offeredIds = data.offeredDriverIds || [];
    const legacyDriverId = data.currentOfferedDriver?.id;

    const allRejectedIds = [...offeredIds];
    if (legacyDriverId && !allRejectedIds.includes(legacyDriverId)) {
      allRejectedIds.push(legacyDriverId);
    }

    if (allRejectedIds.length === 0) return;

    console.log(`Order ${doc.id} expired`,
        `marking ${allRejectedIds.length} drivers as rejected`);

    batch.update(doc.ref, {
      assignmentStatus: "searching", // Retry with next batch of drivers
      rejectedByDrivers: FieldValue.arrayUnion(...allRejectedIds),
      offeredDriverIds: FieldValue.delete(),
      currentOfferedDriver: FieldValue.delete(),
      updatedAt: FieldValue.serverTimestamp(),
    });
  });

  return batch.commit();
});

/**
 * PHASE 2: BROADCAST ASSIGNMENT SYSTEM
 * Instead of offering to 1 driver and waiting 45s, we now:
 * 1. Select TOP 3 nearest drivers
 * 2. Broadcast the offer to all 3 simultaneously
 * 3. First driver to accept wins (race condition handled by transaction)
 * 4. Timeout is now 20 seconds (faster experience)
 */
async function assignToNearestDriver(orderId, orderData) {
  const db = getFirestore();
  const rejectedDrivers = Array.isArray(orderData.rejectedByDrivers) ?
    orderData.rejectedByDrivers : [];

  console.log(`🔍 Searching drivers for order: ${orderId}`);

  // DEBUG: First check ALL drivers to see their status
  const allDriversSnap = await db.collection("delivery").get();
  console.log(`📊 Total drivers in system: ${allDriversSnap.size}`);

  allDriversSnap.forEach((doc) => {
    const d = doc.data();
    console.log(`👤 Driver ${doc.id}: isOnline=${d.isOnline},`,
        `isAvailable=${d.isAvailable}, hasFCM=${!!d.fcmToken}`);
  });

  // 1. Fetch ALL online & available drivers
  const driversSnap = await db.collection("delivery")
      .where("isOnline", "==", true)
      .where("isAvailable", "==", true)
      .get();

  console.log(`✅ Online & Available drivers: ${driversSnap.size}`);

  if (driversSnap.empty) {
    console.log("❌ No drivers online for order", orderId);
    return null;
  }

  // 2. Filter rejected drivers & build list
  let drivers = [];
  driversSnap.forEach((doc) => {
    if (rejectedDrivers.includes(doc.id)) return;
    const dData = doc.data();
    drivers.push({id: doc.id, ...dData});
  });

  console.log(`📝 Eligible drivers after filtering: ${drivers.length}`);

  const pickupLat = orderData.latitude || orderData.pickupLatitude;
  const pickupLng = orderData.longitude || orderData.pickupLongitude;

  // Sort by distance (existing logic)
  drivers = drivers.map((driver) => {
    const dist = getDistance(
        pickupLat,
        pickupLng,
        driver.currentLocation?.latitude,
        driver.currentLocation?.longitude,
    );
    return {...driver, distance: dist};
  }).sort((a, b) => a.distance - b.distance);

  // 3. SELECT TOP 3 DRIVERS (Broadcast Batch)
  const selectedDrivers = drivers.slice(0, 3);

  if (selectedDrivers.length === 0) {
    console.log("All drivers rejected or none available for order", orderId);
    await db.collection("orders").doc(orderId).update({
      assignmentStatus: "failed_no_drivers",
      notificationSentToAdmin: false,
    });
    return null;
  }

  // 4. Update Order with BROADCAST Offer
  const selectedDriverIds = selectedDrivers.map((d) => d.id);

  console.log(`Broadcasting order ${orderId} to`,
      `${selectedDriverIds.length} drivers:`, selectedDriverIds);

  await db.collection("orders").doc(orderId).update({
    status: "Searching",
    assignmentStatus: "broadcasting", // New status for broadcast offers
    offeredDriverIds: selectedDriverIds, // Array of IDs allowed to accept
    assignmentTimeout: Timestamp.fromMillis(Date.now() + 20000), // 20 seconds
    updatedAt: FieldValue.serverTimestamp(),
  });

  // 5. Send FCM to ALL selected drivers simultaneously
  const notificationPromises = selectedDrivers.map((driver) =>
    sendDriverAssignmentNotification(orderId, driver.id),
  );

  return Promise.all(notificationPromises);
}

function getDistance(lat1, lon1, lat2, lon2) {
  if (!lat1 || !lon1 || !lat2 || !lon2) return 99999;
  const R = 6371;
  const dLat = (lat2 - lat1) * Math.PI / 180;
  const dLon = (lon2 - lon1) * Math.PI / 180;
  const a = Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) *
    Math.sin(dLon / 2) * Math.sin(dLon / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c;
}

/**
 * ZOMATO-STYLE HIGH PRIORITY NOTIFICATION
 * - Wakes up device immediately (high priority)
 * - Plays notification sound
 * - Shows heads-up notification
 * - Triggers instant dialog in app
 */
async function sendDriverAssignmentNotification(orderId, driverId) {
  try {
    console.log(`📱 Sending notification to driver: ${driverId}`);

    const db = getFirestore();
    const deliveryDoc = await db.collection("delivery").doc(driverId).get();

    if (!deliveryDoc.exists) {
      console.log(`❌ Driver document not found: ${driverId}`);
      return null;
    }

    const driverData = deliveryDoc.data();
    const token = driverData.fcmToken;
    console.log(`🔑 FCM Token exists: ${!!token}`);
    if (token) {
      console.log(`🔑 Token preview: ${token.substring(0, 30)}...`);
    }

    if (!token) {
      console.log(`❌ No FCM token for driver: ${driverId}`);
      return null;
    }

    // Get order details for rich notification
    const orderDoc = await db.collection("orders").doc(orderId).get();
    const orderData = orderDoc.exists ? orderDoc.data() : {};
    const customerName = orderData.customerSnapshot?.name || "Customer";
    const amount = orderData.totalAmount || 0;

    // Construct High Priority "Offer" Notification
    const message = {
      token: token,
      // 1. Data payload for app to handle logic in background
      data: {
        type: "order_offer", // Distinct type for instant dialog
        orderId: orderId,
        orderNumber: orderData.orderNumber || orderId,
        customerName: customerName,
        amount: amount.toString(),
        timestamp: Date.now().toString(),
        click_action: "FLUTTER_NOTIFICATION_CLICK",
      },
      // 2. Notification payload for system tray
      notification: {
        title: "📢 New Order Offer!",
        body: `${customerName} - ₹${amount.toFixed(0)}. Tap to accept!`,
      },
      // 3. Android High Priority Config (Wakes up device)
      android: {
        priority: "high",
        ttl: 0, // Deliver immediately or fail
        notification: {
          channelId: "order_offer_channel",
          priority: "max",
          visibility: "public",
          sound: "default",
          defaultSound: true,
          defaultVibrateTimings: true,
        },
      },
      // 4. iOS High Priority Config
      apns: {
        headers: {
          "apns-priority": "10", // Immediate delivery
        },
        payload: {
          aps: {
            "alert": {
              "title": "📢 New Order Offer!",
              "body": `${customerName} - ₹${amount.toFixed(0)}. Tap to accept!`,
            },
            "sound": "default",
            "badge": 1,
            "content-available": 1, // Wakes up app in background
          },
        },
      },
    };

    const response = await getMessaging().send(message);
    console.log("High-priority offer sent to driver:", driverId, response);
    return response;
  } catch (error) {
    console.error("Error sending driver assignment notification:", error);
    return null;
  }
}

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
