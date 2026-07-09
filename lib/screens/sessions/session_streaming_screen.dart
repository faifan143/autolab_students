import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../../providers/streaming_provider.dart';

class SessionStreamingScreen extends StatefulWidget {
  const SessionStreamingScreen({super.key});

  @override
  State<SessionStreamingScreen> createState() => _SessionStreamingScreenState();
}

class _SessionStreamingScreenState extends State<SessionStreamingScreen> {
  String? _sessionId;

  @override
  void initState() {
    super.initState();
    _sessionId = Get.arguments as String?;
  }

  @override
  Widget build(BuildContext context) {
    final streamingProvider = Provider.of<StreamingProvider>(context);

    // Initialize streaming on first load
    if (_sessionId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!streamingProvider.isLoading &&
            streamingProvider.shouldAutoLoad(_sessionId!)) {
          streamingProvider.loadStreamingStatus(_sessionId!);
        }
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('watch_live_stream'.tr),
        actions: [
          if (streamingProvider.error != null || !streamingProvider.isStreaming)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _sessionId != null
                  ? () => streamingProvider.reconnect(_sessionId!)
                  : null,
              tooltip: 'reconnect'.tr,
            ),
        ],
      ),
      body: _buildBody(streamingProvider),
    );
  }

  Widget _buildBody(StreamingProvider provider) {
    // Loading state
    if (provider.isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              provider.connectionStatus ?? 'loading'.tr,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }

    // Error state
    if (provider.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              provider.error!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _sessionId != null
                  ? () => provider.reconnect(_sessionId!)
                  : null,
              icon: const Icon(Icons.refresh),
              label: Text('reconnect'.tr),
            ),
          ],
        ),
      );
    }

    // Stream not available
    if (!provider.isStreaming) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.videocam_off, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'stream_not_available'.tr,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'waiting_for_stream'.tr,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }

    // Waiting for stream offer
    if (!provider.hasReceivedOffer) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              provider.connectionStatus ?? 'waiting_for_stream'.tr,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'waiting_for_stream'.tr,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }

    // Stream connected - show placeholder video player
    return _buildStreamPlayer(provider);
  }

  Widget _buildStreamPlayer(StreamingProvider provider) {
    return Column(
      children: [
        // Connection status bar
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          color: provider.isConnected
              ? Colors.green.withOpacity(0.1)
              : Colors.orange.withOpacity(0.1),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                provider.isConnected ? Icons.check_circle : Icons.sync,
                size: 16,
                color: provider.isConnected ? Colors.green : Colors.orange,
              ),
              const SizedBox(width: 8),
              Text(
                provider.connectionStatus ?? 'receiving_stream'.tr,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: provider.isConnected ? Colors.green : Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
        ),

        // Real WebRTC video player
        Expanded(
          child: Container(
            width: double.infinity,
            color: Colors.black,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Always mount the video view once a remote stream is attached;
                // stacked spinner covers until frames paint.
                if (provider.remoteRenderer != null &&
                    provider.hasReceivedOffer)
                  Positioned.fill(
                    child: RTCVideoView(
                      provider.remoteRenderer!,
                      mirror: false,
                      objectFit:
                          RTCVideoViewObjectFit.RTCVideoViewObjectFitContain,
                    ),
                  ),
                if (!provider.isConnected)
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(color: Colors.white),
                      const SizedBox(height: 16),
                      Text(
                        provider.connectionStatus ??
                            (provider.hasReceivedOffer
                                ? 'receiving_stream'.tr
                                : 'waiting_for_stream'.tr),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'watching_live_stream_of_session'.tr,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white70,
                            ),
                      ),
                    ],
                  ),

                // Live indicator
                Positioned(
                  top: 16,
                  left: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'LIVE',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Stream info (if offer received)
                if (provider.streamOffer != null)
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Stream Info',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Session: ${provider.currentSession?.id ?? "N/A"}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.white70,
                                ),
                          ),
                          Text(
                            'Offer received: ${provider.hasReceivedOffer ? "Yes" : "No"}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.white70,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}


