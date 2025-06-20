import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class IroningPreferencesScreen extends StatefulWidget {
  const IroningPreferencesScreen({super.key});

  @override
  State<IroningPreferencesScreen> createState() => _IroningPreferencesScreenState();
}

class _IroningPreferencesScreenState extends State<IroningPreferencesScreen> {
  // Ironing preferences
  String _ironingLevel = 'Medium';
  String _starchLevel = 'Light';
  bool _hangOnHangers = true;
  bool _foldClothes = false;
  String _foldingStyle = 'Standard';
  
  // Fabric care preferences
  bool _delicateFabrics = true;
  bool _steamIroning = false;
  bool _antiWrinkle = true;
  
  // Special instructions
  final TextEditingController _specialInstructionsController = TextEditingController();
  
  // Garment-specific preferences
  Map<String, Map<String, dynamic>> _garmentPreferences = {
    'Shirts': {'ironing': 'High', 'starch': 'Medium', 'hangers': true},
    'T-Shirts': {'ironing': 'Medium', 'starch': 'None', 'hangers': false},
    'Trousers': {'ironing': 'High', 'starch': 'Light', 'hangers': true},
    'Dresses': {'ironing': 'Medium', 'starch': 'Light', 'hangers': true},
    'Jeans': {'ironing': 'Low', 'starch': 'None', 'hangers': false},
  };

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _ironingLevel = prefs.getString('ironing_level') ?? 'Medium';
      _starchLevel = prefs.getString('starch_level') ?? 'Light';
      _hangOnHangers = prefs.getBool('hang_on_hangers') ?? true;
      _foldClothes = prefs.getBool('fold_clothes') ?? false;
      _foldingStyle = prefs.getString('folding_style') ?? 'Standard';
      _delicateFabrics = prefs.getBool('delicate_fabrics') ?? true;
      _steamIroning = prefs.getBool('steam_ironing') ?? false;
      _antiWrinkle = prefs.getBool('anti_wrinkle') ?? true;
      _specialInstructionsController.text = prefs.getString('special_instructions') ?? '';
    });
  }

  Future<void> _savePreference(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is String) {
      await prefs.setString(key, value);
    } else if (value is bool) {
      await prefs.setBool(key, value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Ironing Preferences'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _saveAllPreferences,
            child: const Text('Save'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // General Ironing Preferences
            _buildSection(
              'General Preferences',
              [
                _buildDropdownTile(
                  'Ironing Level',
                  'How crisp do you want your clothes?',
                  Icons.iron,
                  _ironingLevel,
                  ['Light', 'Medium', 'High', 'Extra High'],
                  (value) {
                    setState(() => _ironingLevel = value!);
                    _savePreference('ironing_level', value!);
                  },
                ),
                _buildDropdownTile(
                  'Starch Level',
                  'Amount of starch to apply',
                  Icons.water_drop,
                  _starchLevel,
                  ['None', 'Light', 'Medium', 'Heavy'],
                  (value) {
                    setState(() => _starchLevel = value!);
                    _savePreference('starch_level', value!);
                  },
                ),
                _buildSwitchTile(
                  'Hang on Hangers',
                  'Deliver clothes on hangers',
                  Icons.checkroom,
                  _hangOnHangers,
                  (value) {
                    setState(() => _hangOnHangers = value);
                    _savePreference('hang_on_hangers', value);
                    if (value) {
                      setState(() => _foldClothes = false);
                      _savePreference('fold_clothes', false);
                    }
                  },
                ),
                _buildSwitchTile(
                  'Fold Clothes',
                  'Neatly fold clothes instead of hanging',
                  Icons.layers,
                  _foldClothes,
                  (value) {
                    setState(() => _foldClothes = value);
                    _savePreference('fold_clothes', value);
                    if (value) {
                      setState(() => _hangOnHangers = false);
                      _savePreference('hang_on_hangers', false);
                    }
                  },
                ),
                if (_foldClothes)
                  _buildDropdownTile(
                    'Folding Style',
                    'How would you like clothes folded?',
                    Icons.folder,
                    _foldingStyle,
                    ['Standard', 'Compact', 'Drawer-friendly', 'Travel-ready'],
                    (value) {
                      setState(() => _foldingStyle = value!);
                      _savePreference('folding_style', value!);
                    },
                  ),
              ],
            ),

            const SizedBox(height: 12),

            // Fabric Care
            _buildSection(
              'Fabric Care',
              [
                _buildSwitchTile(
                  'Delicate Fabric Care',
                  'Extra care for delicate fabrics',
                  Icons.favorite,
                  _delicateFabrics,
                  (value) {
                    setState(() => _delicateFabrics = value);
                    _savePreference('delicate_fabrics', value);
                  },
                ),
                _buildSwitchTile(
                  'Steam Ironing',
                  'Use steam for better wrinkle removal',
                  Icons.cloud,
                  _steamIroning,
                  (value) {
                    setState(() => _steamIroning = value);
                    _savePreference('steam_ironing', value);
                  },
                ),
                _buildSwitchTile(
                  'Anti-Wrinkle Treatment',
                  'Apply anti-wrinkle treatment',
                  Icons.auto_fix_high,
                  _antiWrinkle,
                  (value) {
                    setState(() => _antiWrinkle = value);
                    _savePreference('anti_wrinkle', value);
                  },
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Garment-Specific Preferences
            _buildSection(
              'Garment-Specific Preferences',
              [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Text(
                    'Customize preferences for different types of garments',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                ),
                ..._garmentPreferences.entries.map((entry) {
                  return _buildGarmentPreferenceTile(entry.key, entry.value);
                }).toList(),
              ],
            ),

            const SizedBox(height: 12),

            // Special Instructions
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Special Instructions',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F3057),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _specialInstructionsController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'Add any special instructions for ironing your clothes...\n\nExample: Please be extra careful with silk items, avoid high heat on synthetic fabrics, etc.',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.all(12),
                    ),
                    onChanged: (value) {
                      _savePreference('special_instructions', value);
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Quick Presets
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Quick Presets',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F3057),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildPresetButton(
                          'Casual',
                          'Light ironing, no starch',
                          () => _applyPreset('casual'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildPresetButton(
                          'Business',
                          'High ironing, medium starch',
                          () => _applyPreset('business'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildPresetButton(
                          'Formal',
                          'Extra high ironing, heavy starch',
                          () => _applyPreset('formal'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildPresetButton(
                          'Delicate',
                          'Light ironing, special care',
                          () => _applyPreset('delicate'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F3057),
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDropdownTile(
    String title,
    String subtitle,
    IconData icon,
    String value,
    List<String> options,
    Function(String?) onChanged,
  ) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey[700]),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: TextStyle(color: Colors.grey[600])),
      trailing: DropdownButton<String>(
        value: value,
        underline: Container(),
        items: options.map((String option) {
          return DropdownMenuItem<String>(
            value: option,
            child: Text(option),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    Function(bool) onChanged,
  ) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey[700]),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: TextStyle(color: Colors.grey[600])),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: const Color(0xFF0F3057),
      ),
    );
  }

  Widget _buildGarmentPreferenceTile(String garment, Map<String, dynamic> preferences) {
    return ExpansionTile(
      leading: Icon(_getGarmentIcon(garment), color: Colors.grey[700]),
      title: Text(garment, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(
        'Ironing: ${preferences['ironing']}, Starch: ${preferences['starch']}',
        style: TextStyle(color: Colors.grey[600]),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            children: [
              Row(
                children: [
                  const Text('Ironing Level: '),
                  Expanded(
                    child: DropdownButton<String>(
                      value: preferences['ironing'],
                      isExpanded: true,
                      items: ['Low', 'Medium', 'High', 'Extra High'].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _garmentPreferences[garment]!['ironing'] = newValue!;
                        });
                      },
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  const Text('Starch Level: '),
                  Expanded(
                    child: DropdownButton<String>(
                      value: preferences['starch'],
                      isExpanded: true,
                      items: ['None', 'Light', 'Medium', 'Heavy'].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _garmentPreferences[garment]!['starch'] = newValue!;
                        });
                      },
                    ),
                  ),
                ],
              ),
              SwitchListTile(
                title: const Text('Hang on Hangers'),
                value: preferences['hangers'],
                onChanged: (bool value) {
                  setState(() {
                    _garmentPreferences[garment]!['hangers'] = value;
                  });
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPresetButton(String title, String description, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getGarmentIcon(String garment) {
    switch (garment) {
      case 'Shirts':
        return Icons.checkroom;
      case 'T-Shirts':
        return Icons.dry_cleaning;
      case 'Trousers':
        return Icons.straighten;
      case 'Dresses':
        return Icons.woman;
      case 'Jeans':
        return Icons.content_cut;
      default:
        return Icons.checkroom;
    }
  }

  void _applyPreset(String preset) {
    setState(() {
      switch (preset) {
        case 'casual':
          _ironingLevel = 'Light';
          _starchLevel = 'None';
          _hangOnHangers = false;
          _foldClothes = true;
          _steamIroning = false;
          break;
        case 'business':
          _ironingLevel = 'High';
          _starchLevel = 'Medium';
          _hangOnHangers = true;
          _foldClothes = false;
          _steamIroning = true;
          break;
        case 'formal':
          _ironingLevel = 'Extra High';
          _starchLevel = 'Heavy';
          _hangOnHangers = true;
          _foldClothes = false;
          _steamIroning = true;
          _antiWrinkle = true;
          break;
        case 'delicate':
          _ironingLevel = 'Light';
          _starchLevel = 'None';
          _hangOnHangers = true;
          _foldClothes = false;
          _delicateFabrics = true;
          _steamIroning = false;
          break;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${preset.toUpperCase()} preset applied')),
    );
  }

  void _saveAllPreferences() {
    _savePreference('ironing_level', _ironingLevel);
    _savePreference('starch_level', _starchLevel);
    _savePreference('hang_on_hangers', _hangOnHangers);
    _savePreference('fold_clothes', _foldClothes);
    _savePreference('folding_style', _foldingStyle);
    _savePreference('delicate_fabrics', _delicateFabrics);
    _savePreference('steam_ironing', _steamIroning);
    _savePreference('anti_wrinkle', _antiWrinkle);
    _savePreference('special_instructions', _specialInstructionsController.text);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Ironing preferences saved successfully')),
    );
  }

  @override
  void dispose() {
    _specialInstructionsController.dispose();
    super.dispose();
  }
} 