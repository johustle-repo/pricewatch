import 'dart:ui' as ui;

import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_formatters.dart';
import '../../../../core/utils/store_qr_codec.dart';
import '../../../../shared/models/store_model.dart';

class VendorStoreQrScreen extends StatefulWidget {
  const VendorStoreQrScreen({
    super.key,
    required this.store,
    required this.onRefresh,
  });

  final StoreModel store;
  final VoidCallback onRefresh;

  @override
  State<VendorStoreQrScreen> createState() => _VendorStoreQrScreenState();
}

class _VendorStoreQrScreenState extends State<VendorStoreQrScreen> {
  final GlobalKey _posterKey = GlobalKey();
  bool _exporting = false;

  String? get _qrData {
    if (widget.store.id != null) return StoreQrCodec.encode(widget.store);
    final stored = widget.store.qrCode?.trim();
    return stored == null || stored.isEmpty ? null : stored;
  }

  @override
  Widget build(BuildContext context) {
    final qrData = _qrData;
    return ListView(
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 48),
      children: [
        _PageHeading(store: widget.store, onRefresh: widget.onRefresh),
        const SizedBox(height: 22),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 1020;
            final controls = _PrintControls(
              store: widget.store,
              enabled: qrData != null,
              exporting: _exporting,
              onDownload: _downloadPoster,
            );
            final preview = _PosterPreview(
              posterKey: _posterKey,
              store: widget.store,
              qrData: qrData,
            );
            if (!wide) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [controls, const SizedBox(height: 20), preview],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 330, child: controls),
                const SizedBox(width: 24),
                Expanded(child: preview),
              ],
            );
          },
        ),
      ],
    );
  }

  Future<void> _downloadPoster() async {
    final boundary =
        _posterKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null || _exporting) return;
    setState(() => _exporting = true);
    try {
      // 2480 x 3508 is A4 at 300 DPI. The poster uses the exact A4 ratio.
      final pixelRatio = 2480 / boundary.size.width;
      final image = await boundary.toImage(pixelRatio: pixelRatio);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = data?.buffer.asUint8List();
      if (bytes == null) throw StateError('Unable to render poster.');
      final safeName = widget.store.name.toLowerCase().replaceAll(
        RegExp(r'[^a-z0-9]+'),
        '_',
      );
      await FileSaver.instance.saveFile(
        name: '${safeName}_a4_store_qr',
        bytes: bytes,
        fileExtension: 'png',
        mimeType: MimeType.png,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('A4 store poster downloaded.')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not export poster: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }
}

class _PageHeading extends StatelessWidget {
  const _PageHeading({required this.store, required this.onRefresh});

  final StoreModel store;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF172A49), Color(0xFF20395E)],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF385173)),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 24,
        runSpacing: 18,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE91E63), Color(0xFFFF5C89)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.qr_code_2_rounded, color: Colors.white),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'STORE QR & PRINT MATERIALS',
                    style: TextStyle(
                      color: Color(0xFFFF7FA8),
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      letterSpacing: .7,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    store.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  const Text(
                    'Create a counter-ready QR poster for buyer reports.',
                    style: TextStyle(color: Color(0xFFC7D2E3), fontSize: 14),
                  ),
                ],
              ),
            ],
          ),
          OutlinedButton.icon(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Refresh details'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Color(0xFF647793)),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrintControls extends StatelessWidget {
  const _PrintControls({
    required this.store,
    required this.enabled,
    required this.exporting,
    required this.onDownload,
  });

  final StoreModel store;
  final bool enabled;
  final bool exporting;
  final VoidCallback onDownload;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF14243C),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF304765)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'A4 poster controls',
            style: TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 7),
          const Text(
            'The download is rendered at 2480 × 3508 px, ready for A4 printing at 300 DPI.',
            style: TextStyle(color: Color(0xFFB8C5D8), height: 1.45),
          ),
          const SizedBox(height: 22),
          _DetailRow(
            icon: Icons.storefront_rounded,
            label: 'Store',
            value: store.name,
          ),
          _DetailRow(
            icon: Icons.person_outline_rounded,
            label: 'Registered owner',
            value: (store.ownerName ?? '').trim().isEmpty
                ? 'Not specified'
                : store.ownerName!.trim(),
          ),
          _DetailRow(
            icon: Icons.location_on_outlined,
            label: 'Location',
            value: [
              store.address,
              store.city,
            ].where((value) => (value ?? '').trim().isNotEmpty).join(', '),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: enabled && !exporting ? onDownload : null,
            icon: exporting
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.download_rounded),
            label: Text(
              exporting ? 'Preparing A4 poster…' : 'Download A4 poster',
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: enabled
                ? () async {
                    final value = store.id != null
                        ? StoreQrCodec.encode(store)
                        : store.qrCode ?? '';
                    await Clipboard.setData(ClipboardData(text: value));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Store reference copied.'),
                        ),
                      );
                    }
                  }
                : null,
            icon: const Icon(Icons.copy_rounded),
            label: const Text('Copy QR reference'),
          ),
          const SizedBox(height: 18),
          const Divider(color: Color(0xFF304765)),
          const SizedBox(height: 12),
          const Text(
            'PRINTING GUIDE',
            style: TextStyle(
              color: Color(0xFFFF7FA8),
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: .7,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            '• Paper: A4 portrait\n• Scale: Fit to page / 100%\n• Quality: Best or 300 DPI\n• Place near the cashier at eye level',
            style: TextStyle(color: Color(0xFFB8C5D8), height: 1.65),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFFFF6C9A), size: 19),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF8FA1BA),
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PosterPreview extends StatelessWidget {
  const _PosterPreview({
    required this.posterKey,
    required this.store,
    required this.qrData,
  });
  final GlobalKey posterKey;
  final StoreModel store;
  final String? qrData;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF14243C),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF304765)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Live A4 preview',
            style: TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'The downloaded file uses the same layout at full print resolution.',
            style: TextStyle(color: Color(0xFFB8C5D8)),
          ),
          const SizedBox(height: 20),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: RepaintBoundary(
                key: posterKey,
                child: AspectRatio(
                  aspectRatio: 210 / 297,
                  child: _A4Poster(store: store, qrData: qrData),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _A4Poster extends StatelessWidget {
  const _A4Poster({required this.store, required this.qrData});
  final StoreModel store;
  final String? qrData;

  @override
  Widget build(BuildContext context) {
    final owner = (store.ownerName ?? '').trim();
    final market = (store.marketName ?? '').trim();
    final reference = store.id == null
        ? 'Store record'
        : 'PW-${store.id.toString().padLeft(8, '0')}';
    return LayoutBuilder(
      builder: (context, box) {
        final s = box.maxWidth / 560;
        double px(double value) => value * s;
        return Material(
          color: Colors.white,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFE1E6EE), width: px(2)),
            ),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.fromLTRB(px(34), px(30), px(34), px(26)),
                  color: const Color(0xFF172A49),
                  child: Row(
                    children: [
                      Container(
                        width: px(62),
                        height: px(62),
                        padding: EdgeInsets.all(px(6)),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(px(14)),
                        ),
                        child: Image.asset(
                          'assets/icons/lingayen_project_logo.png',
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            Icons.location_city_rounded,
                            color: AppColors.primaryDark,
                            size: px(30),
                          ),
                        ),
                      ),
                      SizedBox(width: px(16)),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'MUNICIPALITY OF LINGAYEN',
                              style: TextStyle(
                                color: const Color(0xFFFF7FA8),
                                fontSize: px(12),
                                fontWeight: FontWeight.w900,
                                letterSpacing: px(.8),
                              ),
                            ),
                            SizedBox(height: px(4)),
                            Text(
                              'VERIFIED MARKET STORE',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: px(23),
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              'PriceWatch public reporting point',
                              style: TextStyle(
                                color: const Color(0xFFC7D2E3),
                                fontSize: px(12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: px(46),
                      vertical: px(20),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: px(14),
                            vertical: px(7),
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F7F1),
                            borderRadius: BorderRadius.circular(px(30)),
                          ),
                          child: Text(
                            '✓  VERIFIED STORE',
                            style: TextStyle(
                              color: const Color(0xFF087A58),
                              fontSize: px(11),
                              fontWeight: FontWeight.w900,
                              letterSpacing: px(.5),
                            ),
                          ),
                        ),
                        SizedBox(height: px(12)),
                        Text(
                          store.name,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: const Color(0xFF111827),
                            fontSize: px(28),
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: px(5)),
                        Text(
                          market.isEmpty ? 'Lingayen Public Market' : market,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: const Color(0xFF647084),
                            fontSize: px(14),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: px(15)),
                        Container(
                          padding: EdgeInsets.all(px(14)),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(px(18)),
                            border: Border.all(
                              color: const Color(0xFFE3CAD6),
                              width: px(2),
                            ),
                          ),
                          child: qrData == null
                              ? SizedBox(
                                  width: px(225),
                                  height: px(225),
                                  child: Center(
                                    child: Text(
                                      'QR unavailable',
                                      style: TextStyle(fontSize: px(16)),
                                    ),
                                  ),
                                )
                              : SizedBox.square(
                                  dimension: px(225),
                                  child: QrImageView(
                                    data: qrData!,
                                    gapless: true,
                                    backgroundColor: Colors.white,
                                  ),
                                ),
                        ),
                        SizedBox(height: px(14)),
                        Text(
                          'SCAN TO REPORT A PRICE',
                          style: TextStyle(
                            color: const Color(0xFF8B1244),
                            fontSize: px(19),
                            fontWeight: FontWeight.w900,
                            letterSpacing: px(.4),
                          ),
                        ),
                        SizedBox(height: px(5)),
                        Text(
                          'Open PriceWatch, scan this code, and submit the commodity and observed price.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: const Color(0xFF4B5565),
                            fontSize: px(12.5),
                            height: 1.35,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(
                            horizontal: px(18),
                            vertical: px(13),
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8EDF2),
                            borderRadius: BorderRadius.circular(px(14)),
                          ),
                          child: Column(
                            children: [
                              Text(
                                owner.isEmpty
                                    ? 'Owner: Not specified'
                                    : 'Owner: $owner',
                                style: TextStyle(
                                  color: const Color(0xFF172033),
                                  fontSize: px(12.5),
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              SizedBox(height: px(4)),
                              Text(
                                [store.address, store.city]
                                    .where((v) => (v ?? '').trim().isNotEmpty)
                                    .join(', '),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: const Color(0xFF647084),
                                  fontSize: px(11.5),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    horizontal: px(30),
                    vertical: px(15),
                  ),
                  color: const Color(0xFF8B1244),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        reference,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: px(10.5),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'Registered ${_date(store.createdAt)}',
                        style: TextStyle(
                          color: const Color(0xFFFAD9E6),
                          fontSize: px(10.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _date(String value) {
    try {
      return AppFormatters.date(value);
    } catch (_) {
      return value;
    }
  }
}
