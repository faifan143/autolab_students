import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    bool validIpPart(String value) {
      final n = int.tryParse(value);
      return n != null && n >= 0 && n <= 255;
    }

    final p1 = _segment1Controller.text.trim();
    final p2 = _segment2Controller.text.trim();
    final p3 = _segment3Controller.text.trim();
    final p4 = _segment4Controller.text.trim();
    final portText = _portController.text.trim();
    final port = int.tryParse(portText);

    if (!validIpPart(p1) ||
        !validIpPart(p2) ||
        !validIpPart(p3) ||
        !validIpPart(p4)) {
      Get.snackbar('error'.tr, 'invalid_ip'.tr, snackPosition: SnackPosition.BOTTOM);
      return;
    }
    if (port == null || port < 1 || port > 65535) {
      Get.snackbar(
        'error'.tr,
        'invalid_port'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final ip = '$p1.$p2.$p3.$p4';

      await StorageService.saveServerIp(ip);
      await StorageService.saveServerPort(portText);

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
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Text('server_configuration'.tr),
      content: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'server_configuration_description'.tr,
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
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
        ),
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
      width: 52,
      child: TextField(
        controller: controller,
        textAlign: TextAlign.center,
        decoration: InputDecoration(
          hintText: hint,
          isDense: true,
        ),
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(3),
        ],
      ),
    );
  }
}