// screens/admin/manage_offers.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/offer_provider.dart';
import '../../models/offer_model.dart';
import '../../widgets/custom_text_field.dart';
import 'package:intl/intl.dart';

class ManageOffers extends StatelessWidget {
  const ManageOffers({super.key});

  @override
  Widget build(BuildContext context) {
    final offerProvider = Provider.of<OfferProvider>(context);

    return Scaffold(
      body: StreamBuilder<List<OfferModel>>(
        stream: offerProvider.getOffersStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('No offers found. Add special offers!'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final offer = snapshot.data![index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  title: Text(offer.title),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(offer.description),
                      Text(
                        'Valid: ${DateFormat('dd/MM/yyyy').format(offer.validFrom)} - ${DateFormat('dd/MM/yyyy').format(offer.validTo)}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${offer.discount}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Switch(
                        value: offer.isActive,
                        onChanged: (value) async {
                          await offerProvider.updateOffer(offer.id, {
                            'isActive': value,
                          });
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteOffer(context, offer.id),
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
        onPressed: () => _showAddDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final discountController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Add Special Offer'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomTextField(
                    controller: titleController,
                    label: 'Offer Title',
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: descriptionController,
                    label: 'Description',
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: discountController,
                    label: 'Discount %',
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final offer = OfferModel(
                    id: '',
                    title: titleController.text,
                    description: descriptionController.text,
                    discount: double.tryParse(discountController.text) ?? 0,
                    validFrom: DateTime.now(),
                    validTo: DateTime.now().add(const Duration(days: 30)),
                    isActive: true,
                  );

                  final offerProvider = Provider.of<OfferProvider>(
                    context,
                    listen: false,
                  );
                  await offerProvider.addOffer(offer);

                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Offer added successfully')),
                    );
                  }
                },
                child: const Text('Add'),
              ),
            ],
          ),
    );
  }
}
  void _deleteOffer(BuildContext context, String offerId) async {
    final offerProvider = Provider.of<OfferProvider>(context, listen: false);
    await offerProvider.deleteOffer(offerId);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Offer deleted successfully')),
      );
    }
  }
