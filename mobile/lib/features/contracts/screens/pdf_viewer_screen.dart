import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/providers/providers.dart';

class PdfViewerScreen extends ConsumerStatefulWidget {
  final String fileUrl;
  final String title;
  const PdfViewerScreen({super.key, required this.fileUrl, required this.title});

  @override
  ConsumerState<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends ConsumerState<PdfViewerScreen> {
  String? _localPath;
  String? _error;
  int _totalPages = 0;
  int _currentPage = 0;
  bool _isReady = false;
  PDFViewController? _controller;

  @override
  void initState() {
    super.initState();
    _download();
  }

  Future<void> _download() async {
    try {
      final tokens = ref.read(tokenStorageProvider);
      final access = await tokens.getAccess();

      final url = widget.fileUrl.startsWith('http')
          ? widget.fileUrl
          : '${ApiConstants.baseUrl}${widget.fileUrl}';

      final dir = await getTemporaryDirectory();
      final fileName = url.split('/').last.split('?').first;
      final localPath = '${dir.path}/$fileName';

      // Validate cached file is real (>1KB and PDF magic bytes)
      Future<bool> isValidPdf(File f) async {
        if (!f.existsSync()) return false;
        final stat = f.statSync();
        if (stat.size < 100) return false;
        try {
          final raf = await f.open();
          final header = await raf.read(4);
          await raf.close();
          // PDF starts with "%PDF"
          return header.length == 4 &&
              header[0] == 0x25 &&
              header[1] == 0x50 &&
              header[2] == 0x44 &&
              header[3] == 0x46;
        } catch (_) {
          return false;
        }
      }

      final cached = File(localPath);
      if (cached.existsSync()) {
        final age = DateTime.now().difference(cached.statSync().modified);
        if (age.inDays < 1 && await isValidPdf(cached)) {
          if (mounted) setState(() => _localPath = localPath);
          return;
        }
        // Stale or corrupted cache - delete and re-download
        try { cached.deleteSync(); } catch (_) {}
      }

      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 60),
      ));
      final res = await dio.download(
        url,
        localPath,
        options: Options(
          headers: access != null ? {'Authorization': 'Bearer $access'} : null,
          responseType: ResponseType.bytes,
        ),
      );

      // Validate the downloaded file
      final downloaded = File(localPath);
      if (!await isValidPdf(downloaded)) {
        try { downloaded.deleteSync(); } catch (_) {}
        if (mounted) {
          setState(() => _error =
              'الملف غير صالح أو محتاج تسجيل دخول جديد (${res.statusCode})');
        }
        return;
      }

      if (mounted) {
        setState(() => _localPath = localPath);
      }
    } on DioException catch (e) {
      if (mounted) {
        final code = e.response?.statusCode;
        String msg;
        if (code == 401) {
          msg = 'انتهت صلاحية الجلسة. سجل دخول من جديد';
        } else if (code == 403) {
          msg = 'غير مصرح بالوصول للملف';
        } else if (code == 404) {
          msg = 'الملف غير موجود';
        } else if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout) {
          msg = 'الاتصال بطيء. حاول مرة أخرى';
        } else if (e.type == DioExceptionType.connectionError) {
          msg = 'تعذر الاتصال بالإنترنت';
        } else {
          msg = 'فشل تحميل الملف${code != null ? " ($code)" : ""}';
        }
        setState(() => _error = msg);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'حدث خطأ: $e');
      }
    }
  }

  Future<void> _share() async {
    if (_localPath == null) return;
    // Capture render box BEFORE async gap (needed for iPad popover anchor)
    final box = context.findRenderObject() as RenderBox?;
    final origin =
        box != null ? box.localToGlobal(Offset.zero) & box.size : null;
    try {
      final cleanTitle = widget.title
          .replaceAll(RegExp(r'[/\\?%*:|"<>]'), '_')
          .replaceAll(RegExp(r'\s+'), '_');
      final friendlyName = '$cleanTitle.pdf';
      final dir = await getTemporaryDirectory();
      final friendlyPath = '${dir.path}/share_$friendlyName';
      await File(_localPath!).copy(friendlyPath);

      await Share.shareXFiles(
        [XFile(friendlyPath, name: friendlyName, mimeType: 'application/pdf')],
        subject: widget.title,
        text: widget.title,
        sharePositionOrigin: origin,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل المشاركة: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          if (_localPath != null)
            IconButton(
              icon: const Icon(Icons.share_outlined),
              tooltip: 'مشاركة',
              onPressed: _share,
            ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: _isReady && _totalPages > 0
          ? Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios, size: 18),
                      onPressed: _currentPage > 0
                          ? () => _controller?.setPage(_currentPage - 1)
                          : null,
                    ),
                    Text(
                      'الصفحة ${_currentPage + 1} من $_totalPages',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    IconButton(
                      icon: const Icon(Icons.arrow_forward_ios, size: 18),
                      onPressed: _currentPage < _totalPages - 1
                          ? () => _controller?.setPage(_currentPage + 1)
                          : null,
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildBody() {
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline,
                size: 64, color: AppColors.danger),
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة'),
              onPressed: () {
                setState(() => _error = null);
                _download();
              },
            ),
          ],
        ),
      );
    }
    if (_localPath == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 12),
            Text('جاري تحميل الملف...'),
          ],
        ),
      );
    }
    return Stack(
      children: [
        PDFView(
          filePath: _localPath!,
          enableSwipe: true,
          swipeHorizontal: false,
          autoSpacing: true,
          pageFling: true,
          pageSnap: true,
          fitPolicy: FitPolicy.WIDTH,
          onRender: (pages) {
            setState(() {
              _totalPages = pages ?? 0;
              _isReady = true;
            });
          },
          onError: (error) {
            setState(() => _error = 'تعذر فتح الملف');
          },
          onViewCreated: (PDFViewController c) {
            _controller = c;
          },
          onPageChanged: (page, total) {
            setState(() {
              _currentPage = page ?? 0;
            });
          },
        ),
        if (!_isReady)
          File(_localPath!).existsSync()
              ? const Center(child: CircularProgressIndicator())
              : const SizedBox.shrink(),
      ],
    );
  }
}
