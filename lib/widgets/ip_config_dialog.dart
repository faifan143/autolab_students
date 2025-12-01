import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/storage_service.dart';
import '../services/api_service.dart';

class IpConfigDialog extends StatefulWidget {
  const IpConfigDialog({super.key});

  @override
  State<IpConfigDialog> createState() => _IpConfigDialogState();
}

class _IpConfigDialogState extends State<IpConfigDialog> {
  final _ipController = TextEditingController();
  final _portController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentConfig();
  }

  Future<void> _loadCurrentConfig() async {
    final ip = await StorageService.getServerIp() ?? '192.168.0.11';
    final port = await StorageService.getServerPort() ?? '3000';
    _ipController.text = ip;
    _portController.text = port;
  }

  Future<void> _saveConfig() async {
    setState(() => _isLoading = true);

    try {
      await StorageService.saveServerIp(_ipController.text.trim());
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
    _ipController.dispose();
    _portController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('server_configuration'.tr),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _ipController,
            decoration: InputDecoration(
              labelText: 'server_ip'.tr,
              hintText: '192.168.0.11',
            ),
            keyboardType: TextInputType.number,
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
}

