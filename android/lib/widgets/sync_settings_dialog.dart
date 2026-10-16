import 'package:flutter/cupertino.dart';
import '../services/sync_service.dart';

class SyncSettingsDialog extends StatefulWidget {
  final VoidCallback onSyncTriggered;

  const SyncSettingsDialog({super.key, required this.onSyncTriggered});

  @override
  State<SyncSettingsDialog> createState() => _SyncSettingsDialogState();
}

class _SyncSettingsDialogState extends State<SyncSettingsDialog> {
  final TextEditingController _urlController = TextEditingController();
  bool _isTesting = false;
  String _statusMsg = '';
  bool _isSuccess = false;

  @override
  void initState() {
    super.initState();
    _loadUrl();
  }

  Future<void> _loadUrl() async {
    final url = await SyncService.getServerUrl();
    _urlController.text = url;
  }

  Future<void> _testConnection() async {
    setState(() {
      _isTesting = true;
      _statusMsg = 'Connecting...';
    });
    final url = _urlController.text.trim();
    await SyncService.setServerUrl(url);

    final res = await SyncService.fetchUserData('usr_default');
    if (mounted) {
      setState(() {
        _isTesting = false;
        if (res != null) {
          _isSuccess = true;
          _statusMsg = '✓ Connected to Sync API Server!';
        } else {
          _isSuccess = false;
          _statusMsg = '✕ Could not reach server. Check IP & WiFi.';
        }
      });
      if (res != null) {
        widget.onSyncTriggered();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPopupSurface(
      child: Container(
        padding: const EdgeInsets.all(20),
        color: const Color(0xFF141824),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Text('📱', style: TextStyle(fontSize: 20)),
                    SizedBox(width: 8),
                    Text(
                      'Live Sync Settings',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: CupertinoColors.white),
                    ),
                  ],
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  child: const Text('Close'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Text(
              'Enter local PC IP (e.g. http://192.168.8.184:3000) or your Vercel deployment URL:',
              style: TextStyle(fontSize: 11, color: CupertinoColors.systemGrey),
            ),
            const SizedBox(height: 12),
            CupertinoTextField(
              controller: _urlController,
              placeholder: 'http://192.168.8.184:3000',
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF1F2538),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0x33FFFFFF)),
              ),
              style: const TextStyle(color: CupertinoColors.white, fontSize: 13),
            ),
            if (_statusMsg.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                _statusMsg,
                style: TextStyle(
                  fontSize: 11,
                  color: _isSuccess ? CupertinoColors.systemGreen : CupertinoColors.systemRed,
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: CupertinoButton.filled(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    onPressed: _isTesting ? null : _testConnection,
                    child: _isTesting
                        ? const CupertinoActivityIndicator(color: CupertinoColors.white)
                        : const Text('Test & Sync Now', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
