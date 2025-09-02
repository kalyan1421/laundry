# 📊 Laundry System Data Structure & Analytics Documentation

## 📋 Overview
This document provides comprehensive information about how orders and users are saved in the Firestore database, enabling developers to create analytics dashboards, graphs, and reports.

---

## 🗄️ Database Collections Structure

### 📁 **Primary Collections**
- `orders/` - All order data
- `customer/` - Customer user data  
- `admins/` - Admin user data
- `delivery_partners/` - Delivery partner data
- `workshop_members/` - Workshop member data
- `items/` - Service items (ironing, allied services)
- `counters/` - Order number counters
- `addresses/` - Customer addresses

---

## 📦 Orders Collection Structure

### 🔑 **Document ID**: Order Number (A000001, A000002, etc.)

### 📊 **Core Order Fields**
```javascript
orders/{orderNumber} = {
  // === BASIC ORDER INFO ===
  id: string,                    // Same as document ID
  customerId: string,            // Customer UID from auth
  orderNumber: string,           // A000001, A000002, etc.
  orderTimestamp: Timestamp,     // When order was created
  serviceType: string,           // "ironing", "laundry", "allied_services"
  status: string,                // Current order status
  orderType: string,             // "pickup_delivery", "drop_off"
  
  // === FINANCIAL DATA ===
  totalAmount: number,           // Total order cost
  totalItemCount: number,        // Total items in order
  paymentMethod: string,         // "cash", "online", "card"
  paymentStatus: string,         // "pending", "paid", "failed"
  transactionId: string,         // Payment gateway transaction ID (optional)
  
  // === ITEMS BREAKDOWN ===
  items: [
    {
      itemId: string,            // Reference to items collection
      itemName: string,          // Display name
      quantity: number,          // Number of items
      price: number,             // Unit price
      subtotal: number,          // quantity * price
      category: string,          // "ironing", "laundry", etc.
      unit: string               // "piece", "kg", etc.
    }
  ],
  
  // === SCHEDULING ===
  pickupDate: Timestamp,         // Scheduled pickup date
  pickupTimeSlot: string,        // "morning", "afternoon", "evening"
  deliveryDate: Timestamp,       // Scheduled delivery date
  deliveryTimeSlot: string,      // "morning", "afternoon", "evening"
  sameAddressForDelivery: boolean, // Address reuse flag
  
  // === ADDRESS INFORMATION ===
  pickupAddress: {
    addressId: string,           // Reference to address document
    formatted: string,           // Display address
    details: {
      doorNumber: string,
      floor: string,
      apartmentName: string,
      addressLine1: string,
      addressLine2: string,
      landmark: string,
      city: string,
      state: string,
      pincode: string,
      addressType: string,       // "home", "work", "other"
      latitude: number,
      longitude: number
    }
  },
  deliveryAddress: {
    // Same structure as pickupAddress
  },
  
  // === ASSIGNMENT & DELIVERY ===
  assignedDeliveryPerson: string,      // Delivery partner UID
  assignedDeliveryPersonName: string,  // Display name
  assignedBy: string,                  // Admin who assigned
  assignedAt: Timestamp,               // When assigned
  isAcceptedByDeliveryPerson: boolean, // Acceptance status
  acceptedAt: Timestamp,               // When accepted
  rejectionReason: string,             // If rejected
  
  // === WORKSHOP ASSIGNMENT (if applicable) ===
  workshopId: string,            // Workshop UID
  assignedTo: string,            // Workshop member UID
  workshopEarnings: number,      // Workshop commission
  memberEarnings: {              // Individual member earnings
    memberId: number
  },
  
  // === NOTIFICATIONS ===
  notificationSentToAdmin: boolean,
  notificationSentToDeliveryPerson: boolean,
  notificationTokens: [string],  // FCM tokens
  notifications: [
    {
      type: string,              // "status_update", "assignment", etc.
      title: string,
      body: string,
      sentAt: Timestamp,
      recipient: string,         // "customer", "admin", "delivery_partner"
      success: boolean
    }
  ],
  
  // === STATUS TRACKING ===
  statusHistory: [
    {
      status: string,            // "pending", "confirmed", "picked_up", etc.
      timestamp: Timestamp,      // When status changed
      updatedBy: string,         // "admin", "delivery_partner", "system"
      title: string,             // Display title
      description: string,       // Status description
      notes: string              // Optional notes (optional)
    }
  ],
  
  // === COMPLETION TRACKING ===
  pickedUpAt: Timestamp,         // Actual pickup time
  deliveredAt: Timestamp,        // Actual delivery time
  cancelledAt: Timestamp,        // If cancelled
  completedAt: Timestamp,        // When fully completed
  
  // === ADDITIONAL INFO ===
  specialInstructions: string,   // Customer notes
  beforeImages: [string],        // Image URLs (optional)
  afterImages: [string],         // Image URLs (optional)
  feedback: {                    // Customer feedback (optional)
    rating: number,              // 1-5 stars
    comment: string,
    createdAt: Timestamp
  },
  
  // === METADATA ===
  createdAt: Timestamp,          // When document created
  updatedAt: Timestamp           // Last update time
}
```

---

## 👥 Users Collection Structure

### 📁 **Customer Collection (`customer/`)**
Document ID: User UID from Firebase Auth

```javascript
customer/{userUID} = {
  // === BASIC INFO ===
  uid: string,                   // Firebase Auth UID
  clientId: string,              // Unique client identifier (C000001, etc.)
  name: string,                  // Full name
  email: string,                 // Email address
  phoneNumber: string,           // Phone with country code
  
  // === PROFILE ===
  profileImageUrl: string,       // Profile photo URL
  qrCodeUrl: string,             // QR code image URL
  isProfileComplete: boolean,    // Profile completion status
  role: string,                  // Always "customer"
  
  // === ANALYTICS DATA ===
  orderCount: number,            // Total orders placed (calculated)
  totalSpent: number,            // Total amount spent (calculated)
  lastOrderDate: Timestamp,      // Most recent order
  averageOrderValue: number,     // AOV calculation
  favoriteServiceType: string,   // Most used service
  
  // === TIMESTAMPS ===
  createdAt: Timestamp,          // Account creation
  updatedAt: Timestamp,          // Last profile update
  lastSignIn: Timestamp          // Last app login
}
```

### 📁 **Customer Addresses Subcollection**
Path: `customer/{userUID}/addresses/{addressId}`

```javascript
addresses/{addressId} = {
  // === ADDRESS DETAILS ===
  doorNumber: string,
  floor: string,
  apartmentName: string,
  addressLine1: string,          // Required
  addressLine2: string,
  landmark: string,
  city: string,                  // Required
  state: string,                 // Required
  pincode: string,               // Required
  
  // === METADATA ===
  addressType: string,           // "home", "work", "other"
  isPrimary: boolean,            // Default address flag
  latitude: number,              // GPS coordinates
  longitude: number,
  
  // === USAGE ANALYTICS ===
  usageCount: number,            // How many times used
  lastUsed: Timestamp,           // Last order with this address
  
  // === TIMESTAMPS ===
  createdAt: Timestamp,
  updatedAt: Timestamp
}
```

### 📁 **Admin Collection (`admins/`)**
```javascript
admins/{adminUID} = {
  uid: string,
  name: string,
  email: string,
  phoneNumber: string,
  role: string,                  // "admin", "super_admin"
  permissions: [string],         // ["orders", "users", "items", etc.]
  isActive: boolean,
  lastActivity: Timestamp,
  createdAt: Timestamp,
  updatedAt: Timestamp
}
```

### 📁 **Delivery Partners Collection (`delivery_partners/`)**
```javascript
delivery_partners/{partnerUID} = {
  uid: string,
  name: string,
  email: string,
  phoneNumber: string,
  vehicleType: string,           // "bike", "car", "bicycle"
  licenseNumber: string,
  isAvailable: boolean,
  currentLocation: {
    latitude: number,
    longitude: number,
    lastUpdated: Timestamp
  },
  totalDeliveries: number,
  rating: number,
  earningsTotal: number,
  isActive: boolean,
  createdAt: Timestamp,
  updatedAt: Timestamp
}
```

---

## 🔢 Order Number Generation System

### 📁 **Counters Collection (`counters/`)**
```javascript
counters/order_counter = {
  value: number,                 // Current counter value
  lastUpdated: Timestamp,        // Last increment time
  createdAt: Timestamp,
  description: string            // "Counter for generating sequential order numbers"
}
```

### 🎯 **Order Number Format**
- **Customer App Orders**: `C000001`, `C000002`, etc.
- **Admin Panel Orders**: `A000001`, `A000002`, etc.
- **Format**: `{Prefix}{6-digit-number}`
- **Generation**: Sequential, atomic using Firestore transactions

---

## 📈 Analytics Query Patterns

### 📊 **Revenue Analytics**
```javascript
// Daily revenue
orders.where('createdAt', '>=', startOfDay)
     .where('createdAt', '<=', endOfDay)
     .where('status', 'in', ['completed', 'delivered'])

// Monthly revenue by service type
orders.where('serviceType', '==', 'ironing')
     .where('createdAt', '>=', startOfMonth)
     .where('status', '==', 'completed')
```

### 📊 **Order Status Distribution**
```javascript
// Orders by status
orders.where('status', '==', 'pending')      // Pending orders
orders.where('status', '==', 'confirmed')    // Confirmed orders
orders.where('status', '==', 'picked_up')    // In progress
orders.where('status', '==', 'delivered')    // Completed
orders.where('status', '==', 'cancelled')    // Cancelled
```

### 📊 **Customer Analytics**
```javascript
// New customers this month
customer.where('createdAt', '>=', startOfMonth)

// Active customers (ordered in last 30 days)
customer.where('lastOrderDate', '>=', thirtyDaysAgo)

// Top customers by spending
customer.orderBy('totalSpent', 'desc').limit(10)
```

### 📊 **Service Type Performance**
```javascript
// Orders by service type
orders.where('serviceType', '==', 'ironing')
orders.where('serviceType', '==', 'laundry')
orders.where('serviceType', '==', 'allied_services')

// Popular items
orders.where('items.category', 'array-contains', 'ironing')
```

### 📊 **Geographic Analytics**
```javascript
// Orders by city
orders.where('pickupAddress.details.city', '==', 'Mumbai')

// Orders by pincode
orders.where('pickupAddress.details.pincode', '==', '400001')

// Delivery partner coverage
delivery_partners.where('currentLocation.latitude', '>=', minLat)
                .where('currentLocation.latitude', '<=', maxLat)
```

### 📊 **Time-based Analytics**
```javascript
// Peak hours analysis
orders.where('pickupTimeSlot', '==', 'morning')
orders.where('pickupTimeSlot', '==', 'afternoon')
orders.where('pickupTimeSlot', '==', 'evening')

// Seasonal trends
orders.where('createdAt', '>=', startOfSeason)
     .where('createdAt', '<=', endOfSeason)
```

---

## 🎯 Key Analytics Metrics

### 💰 **Revenue Metrics**
- **Total Revenue**: Sum of `totalAmount` for completed orders
- **Daily/Monthly/Yearly Revenue**: Grouped by `createdAt`
- **Average Order Value (AOV)**: `totalRevenue / totalOrders`
- **Revenue by Service Type**: Group by `serviceType`
- **Payment Method Distribution**: Group by `paymentMethod`

### 📊 **Order Metrics**
- **Total Orders**: Count of all orders
- **Order Status Distribution**: Count by `status`
- **Order Completion Rate**: `completed_orders / total_orders * 100`
- **Average Fulfillment Time**: `deliveredAt - createdAt`
- **Cancellation Rate**: `cancelled_orders / total_orders * 100`

### 👥 **Customer Metrics**
- **Total Customers**: Count of customer documents
- **New Customer Acquisition**: Count by `createdAt` period
- **Customer Retention Rate**: Repeat customers vs new customers
- **Customer Lifetime Value (CLV)**: `totalSpent` per customer
- **Active Customers**: Customers with orders in last 30 days

### 🚚 **Operations Metrics**
- **Delivery Performance**: `deliveredAt` vs `deliveryDate` comparison
- **Pickup Performance**: `pickedUpAt` vs `pickupDate` comparison
- **Delivery Partner Efficiency**: Orders per partner, ratings
- **Geographic Coverage**: Orders by city/pincode
- **Peak Time Analysis**: Orders by time slots

### 📍 **Service Metrics**
- **Service Type Popularity**: Count by `serviceType`
- **Item Popularity**: Count by `items.itemName`
- **Service Area Coverage**: Unique cities/pincodes served
- **Capacity Utilization**: Orders vs available time slots

---

## 🔍 Sample Analytics Queries

### 📈 **Dashboard KPIs**
```javascript
// Today's metrics
const today = new Date();
const startOfToday = new Date(today.setHours(0,0,0,0));

// Today's revenue
const todayRevenue = await orders
  .where('createdAt', '>=', startOfToday)
  .where('status', 'in', ['completed', 'delivered'])
  .get();

// Today's orders count
const todayOrders = await orders
  .where('createdAt', '>=', startOfToday)
  .get();

// New customers today
const newCustomers = await customer
  .where('createdAt', '>=', startOfToday)
  .get();
```

### 📊 **Trend Analysis**
```javascript
// Monthly revenue trend (last 12 months)
for (let i = 0; i < 12; i++) {
  const monthStart = new Date(now.getFullYear(), now.getMonth() - i, 1);
  const monthEnd = new Date(now.getFullYear(), now.getMonth() - i + 1, 0);
  
  const monthlyRevenue = await orders
    .where('createdAt', '>=', monthStart)
    .where('createdAt', '<=', monthEnd)
    .where('status', '==', 'completed')
    .get();
}
```

### 🎯 **Customer Segmentation**
```javascript
// High-value customers (>₹5000 total spending)
const vipCustomers = await customer
  .where('totalSpent', '>=', 5000)
  .orderBy('totalSpent', 'desc')
  .get();

// Frequent customers (>10 orders)
const frequentCustomers = await customer
  .where('orderCount', '>=', 10)
  .orderBy('orderCount', 'desc')
  .get();
```

---

## 🛠️ Implementation Guidelines

### 📊 **For Dashboard Development**
1. **Real-time Updates**: Use Firestore listeners for live dashboards
2. **Aggregation**: Implement server-side aggregation for large datasets
3. **Caching**: Cache frequently accessed metrics
4. **Pagination**: Implement pagination for large result sets
5. **Indexing**: Create appropriate Firestore indexes for queries

### 📈 **Graph Recommendations**
- **Line Charts**: Revenue trends, order volume over time
- **Bar Charts**: Service type distribution, status distribution
- **Pie Charts**: Payment method breakdown, customer segments
- **Heat Maps**: Geographic distribution, peak hours
- **Tables**: Top customers, recent orders, performance metrics

### 🔐 **Security Considerations**
- Implement proper Firestore security rules
- Use server-side functions for sensitive aggregations
- Mask sensitive customer data in analytics views
- Implement role-based access for different admin levels

---

## 📚 Integration Examples

### 🔄 **Real-time Dashboard**
```javascript
// Listen to new orders
db.collection('orders')
  .where('createdAt', '>=', startOfDay)
  .onSnapshot((snapshot) => {
    updateDashboardMetrics(snapshot.docs);
  });
```

### 📊 **Chart Data Preparation**
```javascript
// Revenue by service type
const revenueByService = {};
orders.forEach(order => {
  const service = order.serviceType;
  revenueByService[service] = (revenueByService[service] || 0) + order.totalAmount;
});
```

### 📈 **Performance Monitoring**
```javascript
// Track order completion times
orders.forEach(order => {
  if (order.status === 'delivered' && order.deliveredAt && order.createdAt) {
    const completionTime = order.deliveredAt.toMillis() - order.createdAt.toMillis();
    // Add to completion time analytics
  }
});
```

---

## ⚡ Quick Reference

### 🗝️ **Key Document Paths**
- Orders: `orders/{orderNumber}`
- Customers: `customer/{userUID}`
- Addresses: `customer/{userUID}/addresses/{addressId}`
- Counter: `counters/order_counter`

### 📊 **Essential Fields for Analytics**
- **Revenue**: `totalAmount`, `paymentStatus`, `status`
- **Time**: `createdAt`, `deliveredAt`, `pickupDate`
- **Customer**: `customerId`, `customerName`
- **Service**: `serviceType`, `items`
- **Location**: `pickupAddress.details.city`, `pincode`
- **Status**: `status`, `statusHistory`

### 🎯 **Common Status Values**
- `pending` → `confirmed` → `picked_up` → `in_progress` → `completed` → `delivered`
- Alternative: `cancelled` at any stage

---

This documentation provides a complete foundation for building comprehensive analytics dashboards and reporting systems for the laundry management platform. 📊✨
