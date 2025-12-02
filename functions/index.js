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

      if (!orderData) return null;

      // Only start search for brand new orders
      const status = orderData.status?.toString().toLowerCase();
      if (status !== "pending" && status !== "new") return null;

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

exports.checkExpiredOffers = onSchedule("every 1 minutes", async () => {
  const db = getFirestore();
  const now = Timestamp.now();

  const staleOrders = await db.collection("orders")
      .where("assignmentStatus", "==", "offered")
      .get();

  if (staleOrders.empty) return null;

  const batch = db.batch();

  staleOrders.forEach((doc) => {
    const data = doc.data();
    const offeredAt = data.currentOfferedDriver?.offeredAt;

    if (!offeredAt || typeof offeredAt.toMillis !== "function") return;

    const diffSeconds = (now.toMillis() - offeredAt.toMillis()) / 1000;
    if (diffSeconds <= 60) return;

    const driverId = data.currentOfferedDriver?.id;
    if (!driverId) return;

    batch.update(doc.ref, {
      assignmentStatus: "searching",
      rejectedByDrivers: FieldValue.arrayUnion(driverId),
      currentOfferedDriver: FieldValue.delete(),
    });

    const driverRef = db.collection("delivery").doc(driverId);
    batch.update(driverRef, {
      currentOffer: FieldValue.delete(),
    });
  });

  return batch.commit();
});

async function assignToNearestDriver(orderId, orderData) {
  const db = getFirestore();
  const rejectedDrivers = Array.isArray(orderData.rejectedByDrivers) ?
    orderData.rejectedByDrivers : [];

  // Fetch online & available drivers
  const driversSnap = await db.collection("delivery")
      .where("isOnline", "==", true)
      .where("isAvailable", "==", true)
      .get();

  if (driversSnap.empty) {
    console.log("No drivers online for order", orderId);
    return null;
  }

  let drivers = [];
  driversSnap.forEach((doc) => {
    if (rejectedDrivers.includes(doc.id)) return;
    const data = doc.data();
    drivers.push({
      id: doc.id,
      ...data,
    });
  });

  if (drivers.length === 0) {
    console.log("All drivers rejected order", orderId);
    await db.collection("orders").doc(orderId).update({
      assignmentStatus: "failed_no_drivers",
      notificationSentToAdmin: false,
    });
    return null;
  }

  const pickupLat = orderData.latitude || orderData.pickupLatitude;
  const pickupLng = orderData.longitude || orderData.pickupLongitude;

  drivers = drivers.map((driver) => {
    const dist = getDistance(
        pickupLat,
        pickupLng,
        driver.currentLocation?.latitude,
        driver.currentLocation?.longitude,
    );
    return {...driver, distance: dist};
  }).sort((a, b) => a.distance - b.distance);

  const bestDriver = drivers[0];
  const orderRef = db.collection("orders").doc(orderId);
  const driverRef = db.collection("delivery").doc(bestDriver.id);

  await db.runTransaction(async (transaction) => {
    const orderSnap = await transaction.get(orderRef);
    if (!orderSnap.exists) {
      throw new Error("Order no longer exists");
    }

    const current = orderSnap.data() || {};
    const currentStatus = current.assignmentStatus;

    // Only assign if still searching/pending
    if (currentStatus && currentStatus !== "searching") {
      console.log("Order already locked/assigned", orderId, currentStatus);
      return;
    }

    transaction.update(orderRef, {
      status: current.status ?? "Searching",
      assignmentStatus: "offered",
      currentOfferedDriver: {
        id: bestDriver.id,
        name: bestDriver.name,
        offeredAt: FieldValue.serverTimestamp(),
      },
      assignmentTimeout: Timestamp.fromMillis(Date.now() + 45000),
    });

    transaction.update(driverRef, {
      currentOffer: {
        orderId: orderId,
        expiresAt: Timestamp.fromMillis(Date.now() + 45000),
      },
    });
  });

  return sendDriverAssignmentNotification(orderId, bestDriver.id);
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

async function sendDriverAssignmentNotification(orderId, driverId) {
  try {
    const deliveryDoc = await getFirestore()
        .collection("delivery")
        .doc(driverId)
        .get();

    if (!deliveryDoc.exists) return null;

    const token = deliveryDoc.data().fcmToken;
    if (!token) return null;

    await getMessaging().send({
      token,
      notification: {
        title: "New Order Request",
        body: `Order #${orderId} is available near you.`,
      },
      data: {
        type: "order_assignment",
        orderId,
      },
    });
  } catch (error) {
    console.error("Error sending driver assignment notification", error);
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
