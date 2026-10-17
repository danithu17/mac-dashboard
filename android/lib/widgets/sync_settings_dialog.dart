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

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _loadUrl() async {
    final url = await SyncService.getServerUrl();
    _urlController.text = url;
  }

  Future<void> _testConnection() async {
    final url = _urlController.text.trim();
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      setState(() {
        _isSuccess = false;
        _statusMsg = '✕ Error: URL must start with http:// or https://';
      });
      return;
    }

    setState(() {
      _isTesting = true;
      _statusMsg = 'Connecting securely...';
    });

    final saved = await SyncService.setServerUrl(url);
    if (!saved) {
      setState(() {
        _isTesting = false;
        _isSuccess = false;
        _statusMsg = '✕ Invalid URL format or hostname.';
      });
      return;
    }

    final res = await SyncService.fetchUserData('usr_default');
    if (mounted) {
      setState(() {
        _isTesting = false;
        if (res != null) {
          _isSuccess = true;
          _statusMsg = '✓ Connected & Synchronized Successfully!';
        } else {
          _isSuccess = false;
          _statusMsg = '✕ Could not reach server. Verify connection & IP.';
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
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0x33007AFF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(CupertinoIcons.arrow_2_circlepath, color: CupertinoColors.systemBlue, size: 18),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Live Sync Settings',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: CupertinoColors.white),
                    ),
                  ],
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  child: const Text('Close', style: TextStyle(fontSize: 14)),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Sync live with your local machine or official Vercel cloud server:',
              style: TextStyle(fontSize: 11, color: CupertinoColors.systemGrey),
            ),
            const SizedBox(height: 12),
            CupertinoTextField(
              controller: _urlController,
              placeholder: SyncService.defaultServerUrl,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              decoration: BoxDecoration(
                color: const Color(0xFF1F2538),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0x33FFFFFF)),
              ),
              style: const TextStyle(color: CupertinoColors.white, fontSize: 13),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                GestureDetector(
                  onTap: () {
                    _urlController.text = SyncService.defaultServerUrl;
                  },
                  child: const Text(
                    'Use Live Cloud (Vercel)',
                    style: TextStyle(fontSize: 10, color: CupertinoColors.systemBlue, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            if (_statusMsg.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                _statusMsg,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: _isSuccess ? CupertinoColors.systemGreen : CupertinoColors.systemRed,
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: CupertinoButton.filled(
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    borderRadius: BorderRadius.circular(12),
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
