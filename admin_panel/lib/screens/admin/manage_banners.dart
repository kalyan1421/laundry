// screens/admin/manage_banners.dart
import 'dart:io';
import 'package:admin_panel/widgets/custom_button.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/banner_provider.dart';
import '../../models/banner_model.dart';

class ManageBanners extends StatefulWidget {
  const ManageBanners({super.key});

  @override
  State<ManageBanners> createState() => _ManageBannersState();
}

class _ManageBannersState extends State<ManageBanners> {
  File? _selectedImage;

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
    _clearSelectedImage();

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        final bannerProvider = Provider.of<BannerProvider>(dialogContext, listen: false);
        bool isLoading = false;

        return StatefulBuilder(
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
                              Container(
                                height: 200,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey[300]!),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(_selectedImage!, fit: BoxFit.cover),
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextButton.icon(
                                icon: const Icon(Icons.clear, color: Colors.red),
                                label: const Text('Remove Image', style: TextStyle(color: Colors.red)),
                                onPressed: () {
                                  setDialogState(() {
                                    _selectedImage = null;
                                  });
                                },
                              ),
                            ],
                          )
                        : Container(
                            height: 200,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: InkWell(
                              onTap: () async {
                                final File? pickedImage = await bannerProvider.pickImage();
                                if (pickedImage != null) {
                                  setDialogState(() {
                                    _selectedImage = pickedImage;
                                  });
                                }
                              },
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_photo_alternate, size: 50, color: Colors.grey[600]),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Tap to select banner image',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            ),
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
                    setDialogState(() => isLoading = true);
                    try {
                      await bannerProvider.addBanner(
                        imageFile: _selectedImage!,
                      );
                      if (mounted) Navigator.of(dialogContext).pop();
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Banner added successfully!')),
                      );
                      _clearSelectedImage();
                    } catch (e) {
                      if (mounted) ScaffoldMessenger.of(dialogContext).showSnackBar(
                        SnackBar(content: Text('Failed to add banner: $e')),
                      );
                    } finally {
                      if(mounted) setDialogState(() => isLoading = false);
                    }
                  },
                  child: isLoading 
                    ? const SizedBox(
                        width: 20, 
                        height: 20, 
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
                      ) 
                    : const Text('Add Banner'),
                ),
              ],
            );
          }
        );
      },
    );
  }

  void _showEditBannerDialog(BuildContext context, BannerModel banner) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        final bannerProvider = Provider.of<BannerProvider>(dialogContext, listen: false);
        bool isActive = banner.isActive;
        bool isLoading = false;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Edit Banner'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 150,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: banner.imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const Center(
                          child: CircularProgressIndicator(),
                        ),
                        errorWidget: (context, url, error) => const Icon(
                          Icons.error, 
                          color: Colors.red, 
                          size: 40
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SwitchListTile(
                    title: const Text('Active Status'),
                    subtitle: Text(isActive ? 'Banner is visible to customers' : 'Banner is hidden'),
                    value: isActive,
                    onChanged: (value) {
                      setDialogState(() {
                        isActive = value;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isLoading ? null : () async {
                    setDialogState(() => isLoading = true);
                    try {
                      await bannerProvider.updateBanner(banner.id, {
                        'isActive': isActive,
                      });
                      if (mounted) Navigator.of(dialogContext).pop();
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Banner updated successfully!')),
                      );
                    } catch (e) {
                      if (mounted) ScaffoldMessenger.of(dialogContext).showSnackBar(
                        SnackBar(content: Text('Failed to update banner: $e')),
                      );
                    } finally {
                      if(mounted) setDialogState(() => isLoading = false);
                    }
                  },
                  child: isLoading 
                    ? const SizedBox(
                        width: 20, 
                        height: 20, 
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
                      ) 
                    : const Text('Update'),
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
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8.0),
                        child: CachedNetworkImage(
                          imageUrl: banner.imageUrl,
                          width: 120,
                          height: 80,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            width: 120,
                            height: 80,
                            color: Colors.grey[200],
                            child: const Center(child: CircularProgressIndicator()),
                          ),
                          errorWidget: (context, url, error) => Container(
                            width: 120,
                            height: 80,
                            color: Colors.grey[200],
                            child: const Icon(Icons.error, color: Colors.red, size: 30),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Banner ${index + 1}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: banner.isActive 
                                  ? Colors.green.withOpacity(0.1) 
                                  : Colors.grey.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                banner.isActive ? 'ACTIVE' : 'INACTIVE',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: banner.isActive ? Colors.green : Colors.grey,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _showEditBannerDialog(context, banner),
                            tooltip: 'Edit Banner',
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
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
                            tooltip: 'Delete Banner',
                          ),
                        ],
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

