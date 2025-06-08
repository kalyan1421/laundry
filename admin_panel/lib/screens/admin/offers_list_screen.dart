import 'package:flutter/material.dart';
import 'package:admin_panel/models/offer_model.dart'; // Adjust path if needed
import 'package:admin_panel/services/offer_service.dart'; // Adjust path if needed
import 'package:admin_panel/services/storage_service.dart'; // Adjust path if needed
import './add_edit_offer_screen.dart'; // Corrected import path
import 'package:intl/intl.dart'; // For date formatting

class OffersListScreen extends StatefulWidget {
  const OffersListScreen({Key? key}) : super(key: key);

  @override
  _OffersListScreenState createState() => _OffersListScreenState();
}

class _OffersListScreenState extends State<OffersListScreen> {
  final OfferService _offerService = OfferService();
  final StorageService _storageService = StorageService();

  void _navigateToAddEditScreen([OfferModel? offer]) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditOfferScreen(offer: offer),
      ),
    ).then((_) {
      // Optional: Refresh list or handle returned data if needed
      // setState(() {}); // May not be needed if using StreamBuilder effectively
    });
  }

  Future<void> _deleteOffer(BuildContext context, OfferModel offer) async {
    bool confirmDelete = await showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: Text('Confirm Delete'),
          content: Text('Are you sure you want to delete the offer "${offer.title}"? This will also delete its image.'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.of(ctx).pop(false),
            ),
            TextButton(
              child: Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () => Navigator.of(ctx).pop(true),
            ),
          ],
        );
      },
    ) ?? false;

    if (confirmDelete && offer.id != null) {
      // Attempt to delete the image from storage first
      if (offer.imageUrl.isNotEmpty) {
        await _storageService.deleteOfferImage(offer.imageUrl);
        // Note: If image deletion fails, we still proceed to delete the Firestore document.
        // You might want to handle this more gracefully depending on requirements.
      }

      // Delete the offer from Firestore
      bool success = await _offerService.deleteOffer(offer.id!);
      
      if (mounted) {
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Offer "${offer.title}" deleted successfully.')),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to delete offer "${offer.title}".')),
            );
          }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<List<OfferModel>>(
        stream: _offerService.getOffers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            print(snapshot.error);
            return Center(child: Text('Error loading offers. ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text(
                'No offers found. Tap the + button to add one!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
            );
          }

          List<OfferModel> offers = snapshot.data!;

          return ListView.builder(
            padding: EdgeInsets.all(8.0),
            itemCount: offers.length,
            itemBuilder: (context, index) {
              OfferModel offer = offers[index];
              return Card(
                margin: EdgeInsets.symmetric(vertical: 8.0),
                elevation: 3,
                child: ListTile(
                  leading: offer.imageUrl.isNotEmpty
                      ? SizedBox(
                          width: 70,
                          height: 70,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4.0),
                            child: Image.network(
                              offer.imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => 
                                Icon(Icons.broken_image, size: 40, color: Colors.grey),
                              loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Center(
                                  child: CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                        : null,
                                  ),
                                );
                              },
                            ),
                          ),
                        )
                      : SizedBox(
                          width: 70,
                          height: 70,
                          child: Icon(Icons.image_not_supported, size: 40, color: Colors.grey),
                        ),
                  title: Text(offer.title, style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Discount: ${offer.discountValue}${offer.discountType == "percentage" ? "%" : " (fixed)"}'),
                      Text('Active: ${offer.isActive ? "Yes" : "No"}', style: TextStyle(color: offer.isActive ? Colors.green : Colors.orange)),
                      Text('Valid: ${DateFormat.yMd().format(offer.validFrom.toDate())} - ${DateFormat.yMd().format(offer.validTo.toDate())}'),
                    ],
                  ),
                  isThreeLine: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit, color: Theme.of(context).primaryColor),
                        onPressed: () => _navigateToAddEditScreen(offer),
                        tooltip: 'Edit Offer',
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.redAccent),
                        onPressed: () => _deleteOffer(context, offer),
                        tooltip: 'Delete Offer',
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'add_offers_list_fab',
        onPressed: () => _navigateToAddEditScreen(),
        tooltip: 'Add New Offer',
        child: Icon(Icons.add),
      ),
    );
  }
} 