// Firebase Admin SDK script to initialize order counter
// Run this once using Node.js with Firebase Admin SDK

const admin = require('firebase-admin');

// Initialize Firebase Admin using Service Account
// Make sure you have downloaded serviceAccountKey.json from Firebase Console
try {
  const serviceAccount = require('./serviceAccountKey.json');
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
    projectId: 'cloudironingfactory-6e53e'
  });
  console.log('✅ Initialized with Service Account');
} catch (error) {
  console.error('❌ Failed to initialize Firebase Admin');
  console.error('💡 Make sure you have:');
  console.error('   1. Downloaded serviceAccountKey.json from Firebase Console');
  console.error('   2. Placed it in the same directory as this script');
  console.error('   3. The file has proper permissions');
  console.error('\nError details:', error.message);
  process.exit(1);
}

const db = admin.firestore();

async function initializeOrderCounter() {
  try {
    const counterRef = db.collection('counters').doc('order_counter');
    
    // Check if counter already exists
    const counterDoc = await counterRef.get();
    
    if (!counterDoc.exists) {
      // Create the counter starting from 0 (first order will be C000001)
      await counterRef.set({
        value: 0,
        lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        description: 'Counter for generating sequential order numbers'
      });
      
      console.log('✅ Order counter initialized successfully');
    } else {
      console.log('ℹ️ Order counter already exists');
      console.log('Current value:', counterDoc.data().value);
    }
    
    process.exit(0);
  } catch (error) {
    console.error('❌ Error initializing order counter:', error);
    process.exit(1);
  }
}

initializeOrderCounter();
