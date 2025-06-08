// screens/admin/manage_banners.dart
import 'dart:io';
import 'package:admin_panel/widgets/custom_button.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/banner_provider.dart';
import '../../models/banner_model.dart';
import '../../widgets/custom_text_field.dart';

class ManageBanners extends StatefulWidget {
  const ManageBanners({super.key});

  @override
  State<ManageBanners> createState() => _ManageBannersState();
}

class _ManageBannersState extends State<ManageBanners> {
  File? _selectedImage;
  final _mainTaglineController = TextEditingController();
  final _subTaglineController = TextEditingController();

  @override
  void dispose() {
    _mainTaglineController.dispose();
    _subTaglineController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final bannerProvider = Provider.of<BannerProvider>(context, listen: false);
    final File? pickedImage = await bannerProvider.pickImage();
    if (pickedImage != null) {
      setState(() {
        _selectedImage = pickedImage;
      });
    }
  }

  void _clearSelectedImage() {
    setState(() {
      _selectedImage = null;
    });
  }

  void _showAddBannerDialog(BuildContext context) {
    _clearSelectedImage(); // Clear previous selection
    _mainTaglineController.clear();
    _subTaglineController.clear();

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        // Use a new context for the dialog to avoid issues with provider
        final bannerProvider = Provider.of<BannerProvider>(dialogContext, listen: false);
        bool isLoading = false;

        return StatefulBuilder( // To update dialog state for loading and image preview
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add New Banner'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    _selectedImage != null
                        ? Column(
                            children: [
                              Image.file(_selectedImage!, height: 150, fit: BoxFit.cover),
                              TextButton.icon(
                                icon: const Icon(Icons.clear, color: Colors.red),
                                label: const Text('Remove Image', style: TextStyle(color: Colors.red)),
                                onPressed: () {
                                  setDialogState(() {
                                    _selectedImage = null;
                                  });
                                  // Also update the state in the main widget if dialog is popped without saving
                                  // This is tricky, direct update is better: _clearSelectedImage(); inside this if needed
                                },
                              ),
                            ],
                          )
                        : CustomButton(
                            text:'Pick Image',
                            onPressed: () async {
                                final File? pickedImage = await bannerProvider.pickImage();
                                if (pickedImage != null) {
                                  setDialogState(() {
                                     _selectedImage = pickedImage;
                                  });
                                }
                            },
                          ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _mainTaglineController,
                      label: 'Main Tagline',
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _subTaglineController,
                      label: 'Sub Tagline',
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor),
                  onPressed: isLoading ? null : () async {
                    if (_selectedImage == null) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(content: Text('Please select an image.')),
                      );
                      return;
                    }
                    if (_mainTaglineController.text.isEmpty || _subTaglineController.text.isEmpty) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(content: Text('Please fill in all taglines.')),
                      );
                      return;
                    }
                    setDialogState(() => isLoading = true);
                    try {
                      await bannerProvider.addBanner(
                        mainTagline: _mainTaglineController.text,
                        subTagline: _subTaglineController.text,
                        imageFile: _selectedImage!,
                      );
                      if (mounted) Navigator.of(dialogContext).pop(); // Close dialog
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Banner added successfully!')),
                      );
                      _clearSelectedImage(); // Clear image for next time
                    } catch (e) {
                      if (mounted) ScaffoldMessenger.of(dialogContext).showSnackBar(
                        SnackBar(content: Text('Failed to add banner: $e')),
                      );
                    } finally {
                       if(mounted) setDialogState(() => isLoading = false);
                    }
                  },
                  child: isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white,)) : const Text('Add Banner'),
                ),
              ],
            );
          }
        );
      },
    );
  }

 @override
  Widget build(BuildContext context) {
    final bannerProvider = Provider.of<BannerProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Banners'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: StreamBuilder<List<BannerModel>>(
        stream: bannerProvider.getBannersStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No banners found. Add some!'));
          }

          final banners = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: banners.length,
            itemBuilder: (context, index) {
              final banner = banners[index];
              return Card(
                elevation: 3,
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8.0),
                        child: CachedNetworkImage(
                          imageUrl: banner.imageUrl,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            width: 100,
                            height: 100,
                            color: Colors.grey[200],
                            child: const Center(child: CircularProgressIndicator()),
                          ),
                          errorWidget: (context, url, error) => Container(
                            width: 100,
                            height: 100,
                            color: Colors.grey[200],
                            child: const Icon(Icons.error, color: Colors.red, size: 40),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              banner.mainTagline,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              banner.subTagline,
                              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.redAccent),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (BuildContext dialogContext) => AlertDialog(
                              title: const Text('Confirm Delete'),
                              content: const Text('Are you sure you want to delete this banner?'),
                              actions: <Widget>[
                                TextButton(
                                  onPressed: () => Navigator.of(dialogContext).pop(false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                                  onPressed: () => Navigator.of(dialogContext).pop(true),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true) {
                            try {
                              await bannerProvider.deleteBanner(banner.id, banner.imageUrl);
                              if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Banner deleted successfully')),
                              );
                            } catch (e) {
                               if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Failed to delete banner: $e')),
                              );
                            }
                          }
                        },
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
        heroTag: 'add_banner_fab',
        child: const Icon(Icons.add_photo_alternate_outlined),
        onPressed: () {
          _showAddBannerDialog(context);
        },
      ),
    );
  }
}

