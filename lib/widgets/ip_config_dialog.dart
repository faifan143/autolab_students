import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../services/api_service.dart';
import '../services/storage_service.dart';

class IpConfigDialog extends StatefulWidget {
  const IpConfigDialog({super.key});

  @override
  State<IpConfigDialog> createState() => _IpConfigDialogState();
}

class _IpConfigDialogState extends State<IpConfigDialog> {
  final _segment1Controller = TextEditingController();
  final _segment2Controller = TextEditingController();
  final _segment3Controller = TextEditingController();
  final _segment4Controller = TextEditingController();
  final _portController = TextEditingController(text: '3000');

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentConfig();
  }

  Future<void> _loadCurrentConfig() async {
    final ip = await StorageService.getServerIp() ?? '192.168.0.11';
    final port = await StorageService.getServerPort() ?? '3000';
    final parts = ip.split('.');
    if (parts.length == 4) {
      _segment1Controller.text = parts[0];
      _segment2Controller.text = parts[1];
      _segment3Controller.text = parts[2];
      _segment4Controller.text = parts[3];
    } else {
      _segment1Controller.text = '192';
      _segment2Controller.text = '168';
      _segment3Controller.text = '0';
      _segment4Controller.text = '11';
    }
    _portController.text = port;
  }

  Future<void> _saveConfig() async {
    setState(() => _isLoading = true);

    try {
      final ip =
          '${_segment1Controller.text.trim()}.${_segment2Controller.text.trim()}.${_segment3Controller.text.trim()}.${_segment4Controller.text.trim()}';

      await StorageService.saveServerIp(ip);
      await StorageService.saveServerPort(_portController.text.trim());

      // Reinitialize Dio with new base URL
      await ApiService.reinitialize();

      if (mounted) {
        Get.back();
        Get.snackbar(
          'success'.tr,
          'server_config_saved'.tr,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      if (mounted) {
        Get.snackbar(
          'error'.tr,
          e.toString(),
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _segment1Controller.dispose();
    _segment2Controller.dispose();
    _segment3Controller.dispose();
    _segment4Controller.dispose();
    _portController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      backgroundColor: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Text('server_configuration'.tr),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'server_configuration_description'.tr,
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildIpSegmentField(_segment1Controller, hint: '192'),
              const Text('.'),
              _buildIpSegmentField(_segment2Controller, hint: '168'),
              const Text('.'),
              _buildIpSegmentField(_segment3Controller, hint: '0'),
              const Text('.'),
              _buildIpSegmentField(_segment4Controller, hint: '11'),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _portController,
            decoration: InputDecoration(
              labelText: 'port'.tr,
              hintText: '3000',
            ),
            keyboardType: TextInputType.number,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Get.back(),
          child: Text('cancel'.tr),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveConfig,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text('save'.tr),
        ),
      ],
    );
  }

  Widget _buildIpSegmentField(TextEditingController controller, {required String hint}) {
    return SizedBox(
      width: 56,
      child: TextField(
        controller: controller,
        textAlign: TextAlign.center,
        decoration: InputDecoration(
          hintText: hint,
        ),
        keyboardType: TextInputType.number,
        maxLength: 3,
      ),
    );
  }
}