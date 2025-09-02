/**
 * Script to remove text fields from existing banner documents in Firestore
 * Run this once to clean up any existing banners that still have text fields
 */

const admin = require('firebase-admin');

// Initialize Firebase Admin SDK
// Use your project credentials
admin.initializeApp({
  projectId: 'cloudironingfactory-6e53e' // Replace with your project ID
});

const db = admin.firestore();

async function cleanupBannerTextFields() {
  try {
    console.log('🧹 Starting cleanup of banner text fields...');
    
    // Get all banner documents
    const bannersRef = db.collection('banners');
    const snapshot = await bannersRef.get();
    
    if (snapshot.empty) {
      console.log('❌ No banners found in Firestore');
      return;
    }
    
    const batch = db.batch();
    let updateCount = 0;
    
    snapshot.forEach((doc) => {
      const data = doc.data();
      console.log(`📄 Processing banner: ${doc.id}`);
      console.log(`   Current data:`, data);
      
      // Check if this document has text fields that need to be removed
      const textFields = [
        'title', 'subtitle', 'description', 'promoText', 
        'mainTagline', 'subTagline', 'actionType', 'actionValue'
      ];
      
      const fieldsToRemove = {};
      let hasTextFields = false;
      
      textFields.forEach(field => {
        if (data.hasOwnProperty(field)) {
          fieldsToRemove[field] = admin.firestore.FieldValue.delete();
          hasTextFields = true;
          console.log(`   ❌ Removing field: ${field} = "${data[field]}"`);
        }
      });
      
      // Also ensure we have the required fields
      const updates = {
        ...fieldsToRemove,
        imageUrl: data.imageUrl || '',
        order: data.order || 0,
        isActive: data.isActive !== undefined ? data.isActive : true,
        updatedAt: admin.firestore.Timestamp.now()
      };
      
      if (hasTextFields || !data.hasOwnProperty('order')) {
        batch.update(doc.ref, updates);
        updateCount++;
        console.log(`   ✅ Scheduled for update`);
      } else {
        console.log(`   ✅ Already clean, no update needed`);
      }
    });
    
    if (updateCount > 0) {
      await batch.commit();
      console.log(`🎉 Successfully cleaned up ${updateCount} banner documents`);
    } else {
      console.log(`🎉 All banners are already clean - no updates needed`);
    }
    
  } catch (error) {
    console.error('❌ Error cleaning up banner text fields:', error);
  }
}

// Run the cleanup
cleanupBannerTextFields()
  .then(() => {
    console.log('✅ Cleanup completed');
    process.exit(0);
  })
  .catch((error) => {
    console.error('❌ Cleanup failed:', error);
    process.exit(1);
  });
