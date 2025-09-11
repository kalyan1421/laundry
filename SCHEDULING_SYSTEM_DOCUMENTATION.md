# Laundry Service - Scheduling System Documentation

## Overview
The current scheduling system in the customer app provides comprehensive pickup and delivery scheduling with time slot management, address selection, and business rule enforcement.

---

## 📅 **Time Slot System**

### Available Time Slots
```
Morning:   7:00 AM - 11:00 AM
Noon:      11:00 AM - 4:00 PM  
Evening:   4:00 PM - 8:00 PM
```

### Time Slot Properties
- **Display Names**: Morning, Noon, Evening
- **Start/End Hours**: Defined for business logic calculations
- **User-Friendly Ranges**: Shown to customers during selection

---

## 📆 **Date Selection Options**

### Pickup Date Options
1. **Today** - Available until 8:00 PM
2. **Tomorrow** - Always available
3. **Custom** - Date picker up to 30 days ahead

### Delivery Date Options
1. **Today** - Only if meets 20-hour constraint
2. **Tomorrow** - Only if meets 20-hour constraint  
3. **Custom** - Date picker with business rule validation

### Business Rules for Dates
- **No Sunday Restrictions**: All days including Sunday are available
- **Late Hour Restriction**: Cannot schedule pickup for "today" after 8:00 PM
- **Future Limit**: Can schedule up to 30 days in advance
- **Same Day**: Delivery can be same day as pickup if time constraints are met

---

## ⏰ **20-Hour Minimum Processing Rule**

### Core Constraint
- **Minimum Gap**: 20 hours between pickup and delivery
- **Calculation**: From pickup time slot start to delivery time slot start
- **Purpose**: Ensures adequate processing time for laundry services

### Implementation
```dart
// Example: Pickup Monday 7 AM → Earliest delivery Tuesday 3 AM
final pickupDateTime = DateTime(pickupDate, startHour: 7);
final minDeliveryDateTime = pickupDateTime.add(Duration(hours: 20));
```

### Time Slot Filtering
- **Same Day**: Only slots starting after minimum time are available
- **Different Day**: All slots available if day meets 20-hour requirement
- **Automatic Validation**: System prevents invalid selections

---

## 🏠 **Address Management System**

### Address Types
- **Home** - Primary residence
- **Work** - Office/workplace  
- **Other** - Custom locations

### Address Selection Flow
1. **Fetch User Addresses**: Load from Firestore customer collection
2. **Primary Selection**: Auto-select primary address if available
3. **Fallback**: Use first address if no primary marked
4. **Same Address Option**: Default to same pickup/delivery location

### Address Components
```dart
- Door Number
- Floor Number  
- Address Line 1 (Street/Building)
- Address Line 2 (Area/Locality)
- Landmark
- City
- State  
- Pincode
- GPS Coordinates (latitude/longitude)
```

### Address Features
- **Add New**: Navigate to AddAddressScreen during scheduling
- **Selection Dialog**: Choose from existing addresses
- **Same Address Toggle**: Use pickup location for delivery
- **Primary Address**: Auto-selected for convenience

---

## 🚚 **Pickup & Delivery Scheduling**

### Initialization Logic
```dart
// Current time check for pickup availability
if (currentHour >= 20) {
    defaultPickupDate = tomorrow;
} else {
    defaultPickupDate = today;
}

// Default delivery: 2 days from pickup
defaultDeliveryDate = minimumDeliveryDate + 1 day;
```

### Scheduling Constraints

#### Pickup Constraints
- **Today Cutoff**: Not available after 8:00 PM
- **Time Slots**: All three slots available for future dates
- **Same Hour Logic**: If current time is close to slot boundary, that slot may be unavailable

#### Delivery Constraints  
- **20-Hour Rule**: Must be at least 20 hours after pickup
- **Dynamic Filtering**: Available slots update based on pickup selection
- **Cross-Day Logic**: Handles delivery on different days correctly

### Available Slot Calculation
```dart
// If delivery is same day as pickup
if (sameDay) {
    // Filter slots starting after minimum delivery time
    availableSlots = slots.where(slot.startTime > minDeliveryTime);
}
// If delivery is different day
else {
    // Check if delivery day meets 20-hour requirement
    if (deliveryDay >= minDeliveryDay) {
        availableSlots = allSlots;
    }
}
```

---

## 💳 **Payment Integration**

### Payment Methods
1. **Cash on Delivery (COD)** - Default option
2. **UPI Payment** - Integrated with UPI apps

### Payment Flow
- **COD**: Order placed immediately, payment on delivery
- **UPI**: Redirects to UPI app selection and payment processing
- **Status Tracking**: Payment status stored with order

---

## 📋 **Order Data Structure**

### Stored Information
```dart
{
  'customerId': userId,
  'orderNumber': serviceSpecificOrderNumber, // CI000001, CL000001, C000001
  'orderTimestamp': currentTimestamp,
  'serviceType': determinedServiceType,
  'items': selectedItemsWithQuantity,
  'totalAmount': calculatedTotal,
  'totalItemCount': sumOfQuantities,
  
  // Scheduling Data
  'pickupDate': selectedPickupDate,
  'pickupTimeSlot': selectedTimeSlot.name,
  'deliveryDate': selectedDeliveryDate,
  'deliveryTimeSlot': selectedTimeSlot.name,
  
  // Address Data
  'pickupAddress': {
    'addressId': addressDocumentId,
    'formatted': formattedAddressString,
    'details': fullAddressObject
  },
  'deliveryAddress': {
    'addressId': addressDocumentId,
    'formatted': formattedAddressString, 
    'details': fullAddressObject
  },
  'sameAddressForDelivery': booleanFlag,
  
  // Additional Info
  'specialInstructions': customerNotes,
  'paymentMethod': selectedPaymentMethod,
  'paymentStatus': currentPaymentStatus,
  'status': 'pending',
  'orderType': 'pickup_delivery'
}
```

---

## 🔄 **User Experience Flow**

### 1. Screen Navigation
- **From Home**: After item selection → Schedule screen
- **From Allied Services**: After service selection → Schedule screen

### 2. Scheduling Steps
1. **Items Summary**: Review selected items and total
2. **Pickup Scheduling**: Select date and time
3. **Address Selection**: Choose pickup location
4. **Delivery Scheduling**: Select date and time (with constraints)
5. **Delivery Address**: Same as pickup or different
6. **Special Instructions**: Optional customer notes
7. **Payment Method**: COD or UPI selection
8. **Order Confirmation**: Final review and placement

### 3. Validation Checks
- **Required Fields**: All date/time/address selections mandatory
- **20-Hour Rule**: Automatic validation before order placement
- **Address Verification**: Ensures pickup and delivery addresses selected
- **Payment Validation**: For UPI payments, ensures successful transaction

---

## 🛡️ **Error Handling & Validation**

### Real-Time Validation
- **Slot Availability**: Updates automatically based on selections
- **Date Constraints**: Prevents invalid date combinations
- **Address Requirements**: Highlights missing address selections
- **Time Logic**: Enforces 20-hour minimum processing time

### Error Messages
- **Late Pickup**: "Cannot schedule pickup for today after 8 PM"
- **Missing Address**: "Please select pickup/delivery address"
- **Time Constraint**: "Delivery must be at least 20 hours after pickup"
- **Invalid Date**: Date picker restrictions prevent invalid selections

### Fallback Handling
- **No Addresses**: Automatically navigates to Add Address screen
- **Primary Address**: Falls back to first address if no primary
- **Payment Failure**: Allows retry or COD fallback

---

## 📱 **User Interface Components**

### Tab Navigation
- **Items Tab**: Order summary and item details
- **Schedule Tab**: Main scheduling interface (default)
- **Address Tab**: Address selection and management

### Interactive Elements
- **Date Chips**: Today/Tomorrow/Custom selection
- **Time Slot Cards**: Visual time range selection
- **Address Cards**: Formatted address display with selection
- **Toggle Switch**: Same address for delivery option
- **Payment Cards**: Method selection with icons

### Visual Feedback
- **Loading States**: Address fetching, order placement
- **Validation Colors**: Green for valid, orange for missing, red for errors
- **Progress Indicators**: Multi-step form completion
- **Confirmation Dialogs**: Order success with details

---

## 🔧 **Technical Implementation**

### State Management
- **Reactive Updates**: Slot availability changes based on selections
- **Form Validation**: Real-time validation of required fields
- **Address Caching**: Stores fetched addresses for session
- **Time Calculations**: Dynamic constraint checking

### Firebase Integration
- **Address Storage**: Customer addresses in subcollection
- **Order Creation**: Single transaction with generated order number
- **Real-time Updates**: Firestore listeners for address changes
- **Authentication**: User-specific data access

### Performance Optimizations
- **Address Caching**: Single fetch per session
- **Lazy Loading**: Address details loaded on demand
- **Debounced Validation**: Prevents excessive calculations
- **Efficient Queries**: Optimized Firestore operations

---

## 📊 **Business Logic Summary**

### Key Features
1. **Flexible Scheduling**: Multiple date/time options with business constraints
2. **Address Management**: Comprehensive address system with GPS support
3. **Service Integration**: Supports different service types (Ironing/Allied/Laundry)
4. **Payment Flexibility**: Multiple payment options with UPI integration
5. **User Experience**: Intuitive interface with real-time validation

### Constraints & Rules
1. **20-Hour Processing**: Minimum time between pickup and delivery
2. **Time Cutoffs**: No same-day pickup after 8 PM
3. **Sunday Operations**: No restrictions on Sunday scheduling
4. **Address Requirements**: Both pickup and delivery addresses mandatory
5. **Service-Specific Orders**: Different numbering for different services

### Data Flow
1. **Item Selection** → **Schedule Screen**
2. **Date/Time Selection** → **Address Selection**  
3. **Validation** → **Payment Method**
4. **Order Creation** → **Confirmation**
5. **Firestore Storage** → **Notification System**

---

This scheduling system provides a comprehensive, user-friendly solution for laundry service booking with robust business rule enforcement and flexible address management.
