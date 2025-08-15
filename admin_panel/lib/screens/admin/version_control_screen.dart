import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';

class VersionControlScreen extends StatefulWidget {
  const VersionControlScreen({Key? key}) : super(key: key);

  @override
  State<VersionControlScreen> createState() => _VersionControlScreenState();
}

class _VersionControlScreenState extends State<VersionControlScreen> {
  final Logger _logger = Logger();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  bool _isLoading = false;
  Map<String, dynamic>? _versionData;
  
  // Form controllers
  final _minVersionController = TextEditingController();
  final _minBuildController = TextEditingController();
  final _latestVersionController = TextEditingController();
  final _latestBuildController = TextEditingController();
  final _updateMessageController = TextEditingController();
  final _playStoreUrlController = TextEditingController();
  final _appStoreUrlController = TextEditingController();
  
  bool _forceUpdate = false;

  @override
  void initState() {
    super.initState();
    _loadVersionData();
  }

  @override
  void dispose() {
    _minVersionController.dispose();
    _minBuildController.dispose();
    _latestVersionController.dispose();
    _latestBuildController.dispose();
    _updateMessageController.dispose();
    _playStoreUrlController.dispose();
    _appStoreUrlController.dispose();
    super.dispose();
  }

  Future<void> _loadVersionData() async {
    setState(() => _isLoading = true);
    
    try {
      final doc = await _firestore
          .collection('app_config')
          .doc('version_control')
          .get();
      
      if (doc.exists) {
        _versionData = doc.data()!;
        _populateControllers();
      } else {
        // Initialize with default values
        await _initializeVersionControl();
      }
    } catch (e) {
      _logger.e('Error loading version data: $e');
      _showSnackBar('Error loading version data: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _populateControllers() {
    if (_versionData != null) {
      _minVersionController.text = _versionData!['min_required_version'] ?? '';
      _minBuildController.text = (_versionData!['min_required_build_number'] ?? 0).toString();
      _latestVersionController.text = _versionData!['latest_version'] ?? '';
      _latestBuildController.text = (_versionData!['latest_build_number'] ?? 0).toString();
      _updateMessageController.text = _versionData!['update_message'] ?? '';
      _playStoreUrlController.text = _versionData!['play_store_url'] ?? '';
      _appStoreUrlController.text = _versionData!['app_store_url'] ?? '';
      _forceUpdate = _versionData!['force_update'] ?? false;
    }
  }

  Future<void> _initializeVersionControl() async {
    try {
      final initialData = {
        'min_required_version': '1.0.0',
        'min_required_build_number': 1,
        'latest_version': '1.4.0',
        'latest_build_number': 15,
        'force_update': false,
        'update_message': 'A new version of Cloud Ironing is available with improved features and bug fixes.',
        'play_store_url': 'https://play.google.com/store/apps/details?id=com.cloudironingfactory.customer',
        'app_store_url': 'https://apps.apple.com/app/cloud-ironing/id123456789',
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection('app_config')
          .doc('version_control')
          .set(initialData);

      _versionData = initialData;
      _populateControllers();
      _showSnackBar('Version control initialized successfully!');
    } catch (e) {
      _logger.e('Error initializing version control: $e');
      _showSnackBar('Error initializing version control: $e', isError: true);
    }
  }

  Future<void> _saveVersionControl() async {
    if (!_validateInputs()) return;

    setState(() => _isLoading = true);

    try {
      final updateData = {
        'min_required_version': _minVersionController.text.trim(),
        'min_required_build_number': int.parse(_minBuildController.text.trim()),
        'latest_version': _latestVersionController.text.trim(),
        'latest_build_number': int.parse(_latestBuildController.text.trim()),
        'force_update': _forceUpdate,
        'update_message': _updateMessageController.text.trim(),
        'play_store_url': _playStoreUrlController.text.trim(),
        'app_store_url': _appStoreUrlController.text.trim(),
        'updated_at': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection('app_config')
          .doc('version_control')
          .update(updateData);

      _showSnackBar('Version control updated successfully!');
      await _loadVersionData(); // Reload data
    } catch (e) {
      _logger.e('Error saving version control: $e');
      _showSnackBar('Error saving version control: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  bool _validateInputs() {
    if (_minVersionController.text.trim().isEmpty ||
        _minBuildController.text.trim().isEmpty ||
        _latestVersionController.text.trim().isEmpty ||
        _latestBuildController.text.trim().isEmpty) {
      _showSnackBar('Please fill all required fields', isError: true);
      return false;
    }

    if (int.tryParse(_minBuildController.text.trim()) == null ||
        int.tryParse(_latestBuildController.text.trim()) == null) {
      _showSnackBar('Build numbers must be valid integers', isError: true);
      return false;
    }

    return true;
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Version Control'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadVersionData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildWarningCard(),
                  const SizedBox(height: 20),
                  _buildCurrentStatusCard(),
                  const SizedBox(height: 20),
                  _buildVersionControlForm(),
                  const SizedBox(height: 20),
                  _buildActionButtons(),
                ],
              ),
            ),
    );
  }

  Widget _buildWarningCard() {
    return Card(
      color: Colors.orange[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning, color: Colors.orange[600]),
                const SizedBox(width: 8),
                Text(
                  'Important Notice',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Changes made here will affect all customer app users immediately. '
              'Force updates will prevent users from using the app until they update. '
              'Please use with caution.',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentStatusCard() {
    if (_versionData == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Current Status',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildStatusRow('Minimum Required Version', 
                '${_versionData!['min_required_version']} (${_versionData!['min_required_build_number']})'),
            _buildStatusRow('Latest Version', 
                '${_versionData!['latest_version']} (${_versionData!['latest_build_number']})'),
            _buildStatusRow('Force Update', 
                _versionData!['force_update'] ? 'ENABLED' : 'Disabled',
                isWarning: _versionData!['force_update']),
            _buildStatusRow('Last Updated', 
                _versionData!['updated_at']?.toDate().toString() ?? 'Unknown'),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, String value, {bool isWarning = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: isWarning ? Colors.red[600] : null,
                fontWeight: isWarning ? FontWeight.bold : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVersionControlForm() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Update Version Control',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            // Minimum Required Version
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _minVersionController,
                    decoration: const InputDecoration(
                      labelText: 'Minimum Required Version *',
                      hintText: '1.4.0',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _minBuildController,
                    decoration: const InputDecoration(
                      labelText: 'Min Build Number *',
                      hintText: '15',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Latest Version
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _latestVersionController,
                    decoration: const InputDecoration(
                      labelText: 'Latest Version *',
                      hintText: '1.5.0',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _latestBuildController,
                    decoration: const InputDecoration(
                      labelText: 'Latest Build Number *',
                      hintText: '16',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Force Update Toggle
            Card(
              color: _forceUpdate ? Colors.red[50] : Colors.grey[50],
              child: SwitchListTile(
                title: const Text('Force Update'),
                subtitle: Text(
                  _forceUpdate 
                      ? 'Users will be REQUIRED to update immediately'
                      : 'Users can choose to update later',
                  style: TextStyle(
                    color: _forceUpdate ? Colors.red[600] : Colors.grey[600],
                  ),
                ),
                value: _forceUpdate,
                onChanged: (value) => setState(() => _forceUpdate = value),
                activeColor: Colors.red,
              ),
            ),
            const SizedBox(height: 16),
            
            // Update Message
            TextFormField(
              controller: _updateMessageController,
              decoration: const InputDecoration(
                labelText: 'Update Message',
                hintText: 'A new version is available...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            
            // Store URLs
            TextFormField(
              controller: _playStoreUrlController,
              decoration: const InputDecoration(
                labelText: 'Play Store URL',
                hintText: 'https://play.google.com/store/apps/details?id=...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _appStoreUrlController,
              decoration: const InputDecoration(
                labelText: 'App Store URL',
                hintText: 'https://apps.apple.com/app/...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _saveVersionControl,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[600],
              foregroundColor: Colors.white,
            ),
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('Save Changes', style: TextStyle(fontSize: 16)),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _isLoading ? null : () => _setForceUpdate(true),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red[600],
                  side: BorderSide(color: Colors.red[600]!),
                ),
                child: const Text('Enable Force Update'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton(
                onPressed: _isLoading ? null : () => _setForceUpdate(false),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.green[600],
                  side: BorderSide(color: Colors.green[600]!),
                ),
                child: const Text('Disable Force Update'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _setForceUpdate(bool enable) async {
    setState(() => _isLoading = true);

    try {
      await _firestore
          .collection('app_config')
          .doc('version_control')
          .update({
        'force_update': enable,
        'updated_at': FieldValue.serverTimestamp(),
      });

      _showSnackBar(
        enable 
            ? 'Force update ENABLED - All users will be required to update'
            : 'Force update disabled - Users can update optionally'
      );
      await _loadVersionData();
    } catch (e) {
      _showSnackBar('Error updating force update setting: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }
}

