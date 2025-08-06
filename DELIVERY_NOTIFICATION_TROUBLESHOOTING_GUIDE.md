# 🚚 Delivery Partner Notification Troubleshooting Guide

## 📋 Overview

This guide helps troubleshoot issues with the delivery partner notification system when admins assign orders to delivery partners.

## ✅ **What Should Happen**

When an admin assigns an order to a delivery partner:

1. **Admin Panel**: Shows confirmation message that order was assigned
2. **Notification Queue**: FCM notification queued in `fcm_notifications` collection
3. **Cloud Function**: Processes the notification and sends to delivery partner's device
4. **Delivery Partner App**: 
   - Receives push notification (even if app is closed)
   - Shows rich notification with order details in foreground
   - Order appears automatically in pickup list
   - Dashboard stats update instantly

## 🔧 **Testing the System**

### **Step 1: Use the Built-in Test Tool**

1. Open **Admin Panel**
2. Go to **Side Menu** → **"Test Delivery Notifications"**
3. Select a delivery partner
4. Click **"Check FCM Tokens"** to verify token setup
5. Click **"Send Test Notification"** to send a test message

### **Step 2: Real Order Assignment Test**

1. Create a test order in the system
2. Open order details in admin panel
3. Assign order to a delivery partner
4. Check if notification appears on delivery partner's device

## 🚨 **Common Issues & Solutions**

### **Issue 1: No Notifications Received**

#### **Possible Causes:**
- ❌ Delivery partner app not properly logged in
- ❌ FCM token not saved in Firestore
- ❌ Cloud Functions not deployed
- ❌ Notification permissions not granted

#### **Solutions:**
```bash
# 1. Check FCM Token Status
- Open Admin Panel → Test Delivery Notifications
- Select delivery partner and click "Check FCM Tokens"
- Should show "✅ Present" for either fcmToken or fcmTokens

# 2. Verify Cloud Functions
firebase deploy --only functions

# 3. Check delivery partner app permissions
- Ensure notification permissions are granted
- Restart delivery partner app after granting permissions
```

### **Issue 2: Notifications Queue but Don't Send**

#### **Possible Causes:**
- ❌ Cloud Functions not deployed
- ❌ Firebase Admin SDK not properly configured
- ❌ Invalid FCM tokens

#### **Solutions:**
```bash
# 1. Deploy Cloud Functions
cd functions
firebase deploy --only functions

# 2. Check Firebase Console
- Go to Firebase Console → Functions
- Verify "processFcmNotifications" function is deployed
- Check function logs for errors

# 3. Check Firestore
- Go to Firestore → fcm_notifications collection
- Verify notification documents have status "sent" (not "pending" or "failed")
```

### **Issue 3: Delivery Partner Can't Login**

#### **Possible Causes:**
- ❌ Phone index not created
- ❌ Delivery partner not properly created by admin
- ❌ Authentication rules blocking access

#### **Solutions:**
```bash
# 1. Run Migration (Admin Panel)
- Go to Admin Panel → Dashboard
- Click "Run Migration" button
- This creates phone index for existing delivery partners

# 2. Verify delivery partner status
- Go to Admin Panel → Delivery Staff
- Ensure partner status is "Active"
- Check that phone number matches exactly
```

### **Issue 4: Real-Time Updates Not Working**

#### **Possible Causes:**
- ❌ Firestore rules blocking reads
- ❌ Internet connectivity issues
- ❌ App in background with restricted permissions

#### **Solutions:**
```bash
# 1. Check Firestore Rules
firebase deploy --only firestore:rules

# 2. Test connectivity
- Pull down to refresh in delivery partner app
- Check internet connection
- Restart delivery partner app
```

## 🔍 **Debugging Steps**

### **Step 1: Check Admin Panel Logs**
```dart
// Look for these log messages when assigning order:
🚚 Order assignment notification sent to delivery partner: [Name]
📱 Order ID: [OrderID]
📦 Order Number: [OrderNumber]
```

### **Step 2: Check FCM Service Logs**
```dart
// Look for these log messages in console:
🚚 📱 Found [X] FCM token(s) for delivery partner: [Name]
🚚 ✅ Push notification sent to delivery partner: [Name]
FCM: [X] notifications queued for sending
```

### **Step 3: Check Cloud Function Logs**
```bash
# In Firebase Console → Functions → Logs
Processing FCM notification: [ID]
FCM notification sent successfully: [response]
```

### **Step 4: Check Delivery Partner App Logs**
```dart
// Look for these log messages:
🚚 📦 NEW ORDER ASSIGNMENT RECEIVED!
🚚 Order Number: [OrderNumber]
🚚 Customer: [CustomerName]
🚚 📦 OrderProvider: Handling new order assignment notification
```

## 📊 **Firestore Collections to Check**

### **1. `delivery` Collection**
```json
{
  "name": "John Doe",
  "phoneNumber": "+91XXXXXXXXXX",
  "isActive": true,
  "fcmToken": "xxx...xxx",  // ← Should be present
  "uid": "firebase_auth_uid" // ← Should be present after login
}
```

### **2. `delivery_phone_index` Collection**
```json
{
  "deliveryPartnerId": "partner_doc_id",
  "phoneNumber": "+91XXXXXXXXXX",
  "isActive": true,
  "linkedToUID": "firebase_auth_uid"
}
```

### **3. `fcm_notifications` Collection**
```json
{
  "token": "fcm_token_here",
  "title": "New Order Assignment",
  "body": "You have been assigned...",
  "status": "sent", // ← Should be "sent", not "pending" or "failed"
  "timestamp": "2024-01-15T10:30:00Z"
}
```

### **4. `orders` Collection**
```json
{
  "assignedDeliveryPerson": "partner_doc_id", // ← Should be present
  "status": "assigned", // ← Should be "assigned" after assignment
  "assignedAt": "2024-01-15T10:30:00Z"
}
```

## 🛠️ **Manual Fixes**

### **Fix 1: Manually Save FCM Token**
```dart
// If delivery partner app login but token not saved:
// 1. Login to delivery partner app
// 2. Pull down to refresh dashboard
// 3. Check Admin Panel → Test Notifications → Check FCM Tokens
```

### **Fix 2: Reset Delivery Partner Authentication**
```bash
# 1. In Admin Panel → Delivery Staff
# 2. Edit delivery partner
# 3. Change status to Inactive → Save
# 4. Change status to Active → Save
# 5. Ask delivery partner to login again
```

### **Fix 3: Manually Create Phone Index**
```bash
# 1. Go to Admin Panel → Dashboard
# 2. Click "Run Migration"
# 3. Wait for completion message
# 4. Test delivery partner login again
```

## 📱 **Device-Specific Issues**

### **Android Devices**
- Ensure "Background App Refresh" is enabled
- Check "Do Not Disturb" settings
- Verify app is not "battery optimized" (whitelist the app)
- Test with app in foreground and background

### **iOS Devices**
- Ensure notification permissions are granted
- Check "Settings → Notifications → [App Name]"
- Verify "Background App Refresh" is enabled
- Test with app in foreground and background

### **Web Browsers**
- Notification permissions must be granted
- Works best in Chrome/Edge browsers
- May not work in incognito/private mode
- Check browser notification settings

## 🎯 **Performance Optimization**

### **Expected Timing**
- **Order Assignment to Notification Queue**: < 1 second
- **Cloud Function Processing**: 1-3 seconds
- **Notification Delivery**: 1-5 seconds (total)
- **Real-time List Updates**: < 1 second

### **If Performance is Slow**
1. Check internet connectivity
2. Verify Cloud Functions are deployed in same region
3. Check Firebase project quota limits
4. Monitor Firestore read/write usage

## 🆘 **Emergency Fixes**

### **Quick Reset All**
```bash
# 1. Deploy everything fresh
firebase deploy

# 2. Restart all apps
# 3. Clear app cache if necessary
# 4. Run migration in admin panel
# 5. Test with "Test Delivery Notifications"
```

### **Fallback Communication**
If notifications fail completely:
1. Use phone calls to inform delivery partners
2. Send SMS messages manually
3. Use WhatsApp or other messaging apps
4. Check order status in delivery partner app manually

## 📞 **Contact Support**

If issues persist after following this guide:
1. Collect logs from all components
2. Document exact error messages
3. Note device types and OS versions
4. Provide steps to reproduce the issue

---

## ✅ **System Status Checklist**

Use this checklist to verify system health:

- [ ] Cloud Functions deployed successfully
- [ ] Firestore rules allow delivery partner access
- [ ] Phone index migration completed
- [ ] Test notifications work in admin panel
- [ ] Real-time order updates functional
- [ ] Delivery partner app login working
- [ ] FCM tokens being saved correctly
- [ ] Order assignment creates notifications
- [ ] Notification processing completes
- [ ] Delivery partners receive notifications

**All checkboxes should be ✅ for full system functionality.** 