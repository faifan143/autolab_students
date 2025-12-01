import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import '../../providers/streaming_provider.dart';

class SessionStreamingScreen extends StatelessWidget {
  const SessionStreamingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sessionId = Get.arguments as String;
    final streamingProvider = Provider.of<StreamingProvider>(context);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      streamingProvider.loadStreamingStatus(sessionId);
    });

    // Viewer-only scaffold, ready for future WebRTC integration
    return Scaffold(
      appBar: AppBar(
        title: Text('watch_live_stream'.tr),
      ),
      body: streamingProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.live_tv, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'watching_live_stream_of_session'.tr,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'TODO: WebRTC integration with Mediasoup',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  // TODO: Future WebRTC viewer implementation
                  // - Initialize Mediasoup consumer
                  // - Display video stream
                  // - Handle audio
                ],
              ),
            ),
    );
  }
}


