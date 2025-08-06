// create_phone_index.js - Node.js script to create phone index for delivery partners
const admin = require('firebase-admin');

// Initialize Firebase Admin (using default credentials)
try {
  admin.initializeApp();
} catch (error) {
  console.log('Firebase admin already initialized or error:', error.message);
}

const db = admin.firestore();

async function createPhoneIndexForDeliveryPartners() {
  console.log('🔍 Creating phone index for delivery partners...');
  
  try {
    // Get all delivery partners
    const deliverySnapshot = await db.collection('delivery').get();
    console.log(`📋 Found ${deliverySnapshot.docs.length} delivery partners`);
    
    const batch = db.batch();
    let indexCount = 0;
    
    for (const doc of deliverySnapshot.docs) {
      const data = doc.data();
      const phoneNumber = data.phoneNumber;
      
      if (phoneNumber) {
        // Format phone key (remove + sign)
        const phoneKey = phoneNumber.replace('+', '');
        
        console.log(`📞 Creating index for ${data.name}: ${phoneNumber} -> ${phoneKey}`);
        
        // Create phone index document
        const indexRef = db.collection('delivery_phone_index').doc(phoneKey);
        batch.set(indexRef, {
          phoneNumber: phoneNumber,
          deliveryPartnerId: doc.id,
          deliveryPartnerName: data.name || 'Unknown',
          isActive: data.isActive || false,
          createdAt: admin.firestore.Timestamp.now(),
          linkedToUID: data.uid || null,
          linkedAt: data.uid ? admin.firestore.Timestamp.now() : null,
        });
        
        indexCount++;
      } else {
        console.log(`⚠️ No phone number found for delivery partner: ${doc.id}`);
      }
    }
    
    // Commit the batch
    await batch.commit();
    console.log(`✅ Successfully created ${indexCount} phone index entries`);
    
    // Test reading the phone index for the specific number from error
    console.log('\n🔍 Testing phone index lookup for 919063290001...');
    const testDoc = await db.collection('delivery_phone_index').doc('919063290001').get();
    
    if (testDoc.exists) {
      console.log('✅ Phone index entry found:', testDoc.data());
    } else {
      console.log('❌ Phone index entry not found for 919063290001');
      
      // Check if there's a delivery partner with this phone number
      const phoneQuery = await db.collection('delivery')
        .where('phoneNumber', '==', '+919063290001')
        .limit(1)
        .get();
      
      if (!phoneQuery.empty) {
        const partnerData = phoneQuery.docs[0].data();
        console.log('📋 Found delivery partner with this phone:', partnerData.name);
        console.log('🔧 Creating missing phone index entry...');
        
        await db.collection('delivery_phone_index').doc('919063290001').set({
          phoneNumber: '+919063290001',
          deliveryPartnerId: phoneQuery.docs[0].id,
          deliveryPartnerName: partnerData.name || 'Unknown',
          isActive: partnerData.isActive || false,
          createdAt: admin.firestore.Timestamp.now(),
          linkedToUID: partnerData.uid || null,
          linkedAt: partnerData.uid ? admin.firestore.Timestamp.now() : null,
        });
        
        console.log('✅ Phone index entry created successfully');
      } else {
        console.log('❌ No delivery partner found with phone +919063290001');
        console.log('💡 You may need to create a delivery partner account first');
      }
    }
    
  } catch (error) {
    console.error('❌ Error creating phone index:', error);
  }
}

async function listDeliveryPartners() {
  console.log('\n📋 Listing all delivery partners...');
  
  try {
    const snapshot = await db.collection('delivery').get();
    console.log(`Found ${snapshot.docs.length} delivery partners:`);
    
    snapshot.docs.forEach((doc, index) => {
      const data = doc.data();
      console.log(`\n${index + 1}. ID: ${doc.id}`);
      console.log(`   Name: ${data.name || 'N/A'}`);
      console.log(`   Phone: ${data.phoneNumber || 'N/A'}`);
      console.log(`   Active: ${data.isActive || false}`);
      console.log(`   UID: ${data.uid || 'Not linked'}`);
      console.log(`   Email: ${data.email || 'N/A'}`);
    });
  } catch (error) {
    console.error('❌ Error listing delivery partners:', error);
  }
}

async function testFirestoreRules() {
  console.log('\n🛡️ Testing Firestore rules...');
  
  try {
    // Test 1: Read delivery_phone_index (should work with admin)
    console.log('📞 Testing delivery_phone_index read...');
    const indexSnapshot = await db.collection('delivery_phone_index').limit(1).get();
    console.log(`✅ Successfully read delivery_phone_index (${indexSnapshot.docs.length} docs)`);
    
    // Test 2: Read delivery collection (should work with admin)
    console.log('🚚 Testing delivery collection read...');
    const deliverySnapshot = await db.collection('delivery').limit(1).get();
    console.log(`✅ Successfully read delivery collection (${deliverySnapshot.docs.length} docs)`);
    
    console.log('✅ All admin-level tests passed');
    
  } catch (error) {
    console.error('❌ Error testing Firestore rules:', error);
  }
}

// Run the functions
async function main() {
  console.log('🚀 Starting Firebase admin operations...');
  
  await listDeliveryPartners();
  await createPhoneIndexForDeliveryPartners();
  await testFirestoreRules();
  
  console.log('\n🎉 All operations completed!');
  process.exit(0);
}

main().catch(console.error);
