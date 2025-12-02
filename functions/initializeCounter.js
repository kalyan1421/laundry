// Firebase Function to initialize order counter
// This is a utility file - not deployed as a function

const admin = require("firebase-admin");
const {onRequest} = require("firebase-functions/v2/https");

// Function to initialize order counter (call once via HTTP)
exports.initializeOrderCounter = onRequest(async (req, res) => {
  try {
    // Security: Only allow this in development or with proper auth
    if (req.method !== "POST") {
      return res.status(405).send("Method not allowed. Use POST.");
    }

    const db = admin.firestore();
    const counterRef = db.collection("counters").doc("order_counter");

    // Check if counter already exists
    const counterDoc = await counterRef.get();

    if (!counterDoc.exists) {
      // Create the counter starting from 0 (first order will be C000001)
      await counterRef.set({
        value: 0,
        lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        description: "Counter for generating sequential order numbers",
      });

      console.log("Order counter initialized successfully");
      res.status(200).json({
        success: true,
        message: "Order counter initialized successfully",
        initialValue: 0,
      });
    } else {
      console.log("Order counter already exists");
      res.status(200).json({
        success: true,
        message: "Order counter already exists",
        currentValue: counterDoc.data().value,
      });
    }
  } catch (error) {
    console.error("Error initializing order counter:", error);
    res.status(500).json({
      success: false,
      error: error.message,
    });
  }
});
