import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/store_qr_codec.dart';
import '../../../../shared/widgets/app_notification_button.dart';

class StoreQrScannerScreen extends StatefulWidget {
  const StoreQrScannerScreen({super.key, this.openReportOnScan = false});

  final bool openReportOnScan;

  @override
  State<StoreQrScannerScreen> createState() => _StoreQrScannerScreenState();
}

class _StoreQrScannerScreenState extends State<StoreQrScannerScreen> {
  late final MobileScannerController _controller;
  bool _handled = false;
  String? _scannerError;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(autoStart: false);
    WidgetsBinding.instance.addPostFrameCallback((_) => _startScanner());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _startScanner() async {
    try {
      await _controller.start();
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _scannerError = _readableScannerError(error);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final useWebShell = MediaQuery.sizeOf(context).width >= 1024;
    return Scaffold(
      appBar: useWebShell
          ? null
          : AppBar(
              title: const Text('Scan Store QR'),
              actions: const [AppNotificationButton(), SizedBox(width: 8)],
            ),
      body: _scannerError != null
          ? _ScannerErrorView(
              message: _scannerError!,
              onRetry: () {
                setState(() => _scannerError = null);
                _startScanner();
              },
            )
          : Stack(
              children: [
                MobileScanner(
                  controller: _controller,
                  onDetect: (capture) {
                    if (_handled) {
                      return;
                    }
                    final values = capture.barcodes
                        .map((item) => item.rawValue?.trim())
                        .whereType<String>();
                    if (values.isEmpty) {
                      return;
                    }
                    try {
                      final payload = StoreQrCodec.decode(values.first);
                      _handled = true;
                      if (widget.openReportOnScan) {
                        context.go('/report/new?storeId=${payload.storeId}');
                        return;
                      }
                      Navigator.of(context).pop(payload);
                    } catch (_) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'This is not a valid PriceWatch store QR.',
                          ),
                        ),
                      );
                    }
                  },
                  errorBuilder: (context, error) {
                    return _ScannerErrorView(
                      message: _readableScannerError(error),
                      onRetry: () {
                        setState(() => _scannerError = null);
                        _startScanner();
                      },
                    );
                  },
                  placeholderBuilder: (context) => Container(
                    color: Colors.black,
                    alignment: Alignment.center,
                    child: const CircularProgressIndicator(),
                  ),
                ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: Center(
                      child: Container(
                        width: 240,
                        height: 240,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: AppSpacing.lg,
                  right: AppSpacing.lg,
                  bottom: AppSpacing.xl,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceFor(context).withValues(
                        alpha: AppColors.isDark(context) ? 0.92 : 0.96,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.borderFor(context)),
                    ),
                    child: Text(
                      'Scan a store QR to auto-fill the report with that store.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  String _readableScannerError(Object error) {
    final text = error.toString().toLowerCase();
    if (text.contains('permission')) {
      return 'Camera permission was denied. Please allow camera access and try again.';
    }
    if (text.contains('no camera') || text.contains('not found')) {
      return 'No usable camera was found on this device or emulator.';
    }
    return 'The QR scanner could not start on this device right now.';
  }
}

class _ScannerErrorView extends StatelessWidget {
  const _ScannerErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surfaceFor(context),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.borderFor(context)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.qr_code_scanner_rounded,
                size: 42,
                color: AppColors.primary,
              ),
              const SizedBox(height: 14),
              Text(
                'Scanner unavailable',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try again'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
