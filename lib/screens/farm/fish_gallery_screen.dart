import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/server_config.dart';

class FishGalleryScreen extends StatefulWidget {
  final String tankId;
  final String tankName;

  const FishGalleryScreen({super.key, required this.tankId, required this.tankName});

  @override
  State<FishGalleryScreen> createState() => _FishGalleryScreenState();
}

class _FishGalleryScreenState extends State<FishGalleryScreen> {
  List<Map<String, dynamic>> _photos = [];
  bool _loading = true;
  String? _error;
  String _baseUrl = '';

  @override
  void initState() {
    super.initState();
    _loadPhotos();
  }

  Future<void> _loadPhotos() async {
    setState(() { _loading = true; _error = null; });

    final url = await ServerConfig.getUrl();
    if (url.isEmpty) {
      setState(() { _loading = false; _error = 'server_not_configured'; });
      return;
    }

    _baseUrl = url;

    try {
      final res = await http
          .get(Uri.parse('$url/api/tanks/${widget.tankId}/photos'))
          .timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          _photos = List<Map<String, dynamic>>.from(data['photos']);
          _loading = false;
        });
      } else {
        setState(() { _loading = false; _error = '서버 오류 (${res.statusCode})'; });
      }
    } catch (e) {
      setState(() { _loading = false; _error = '서버에 연결할 수 없습니다.\n($e)'; });
    }
  }

  void _openPhoto(int index) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => _PhotoViewScreen(
        photos: _photos,
        initialIndex: index,
        baseUrl: _baseUrl,
        tankName: widget.tankName,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.tankName, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
            const Text('불량어류 사진', style: TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPhotos,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Color(0xFF2563EB)),
            SizedBox(height: 12),
            Text('사진 불러오는 중...', style: TextStyle(color: Color(0xFF6B7280))),
          ],
        ),
      );
    }

    if (_error == 'server_not_configured') {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off, size: 64, color: Color(0xFFD1D5DB)),
            const SizedBox(height: 16),
            const Text('서버 주소가 설정되지 않았습니다', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1F2937))),
            const SizedBox(height: 8),
            const Text('설정 메뉴에서 젯슨 나노 서버 IP를 입력해주세요', style: TextStyle(color: Color(0xFF6B7280))),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.settings),
              label: const Text('돌아가기'),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Color(0xFFEF4444)),
              const SizedBox(height: 16),
              const Text('연결 실패', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1F2937))),
              const SizedBox(height: 8),
              Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13)),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _loadPhotos,
                icon: const Icon(Icons.refresh),
                label: const Text('다시 시도'),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white),
              ),
            ],
          ),
        ),
      );
    }

    if (_photos.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.photo_library_outlined, size: 64, color: Color(0xFFD1D5DB)),
            SizedBox(height: 12),
            Text('등록된 불량어류 사진이 없습니다', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF9CA3AF))),
          ],
        ),
      );
    }

    return Column(
      children: [
        // 사진 수 표시
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: Colors.white,
          child: Text(
            '총 ${_photos.length}장 (최신순)',
            style: const TextStyle(color: Color(0xFF6B7280), fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ),
        // 그리드
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(4),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 3,
              mainAxisSpacing: 3,
            ),
            itemCount: _photos.length,
            itemBuilder: (ctx, i) {
              final photo = _photos[i];
              final imageUrl = '$_baseUrl${photo['url']}';
              return GestureDetector(
                onTap: () => _openPhoto(i),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        color: const Color(0xFFE5E7EB),
                        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        color: const Color(0xFFF3F4F6),
                        child: const Icon(Icons.broken_image, color: Color(0xFF9CA3AF)),
                      ),
                    ),
                    // 날짜 오버레이
                    Positioned(
                      bottom: 0, left: 0, right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        color: Colors.black45,
                        child: Text(
                          _formatDate(photo['captured_at'] ?? ''),
                          style: const TextStyle(color: Colors.white, fontSize: 9),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso);
      return '${dt.month}/${dt.day} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }
}

// 전체화면 사진 뷰어
class _PhotoViewScreen extends StatefulWidget {
  final List<Map<String, dynamic>> photos;
  final int initialIndex;
  final String baseUrl;
  final String tankName;

  const _PhotoViewScreen({
    required this.photos,
    required this.initialIndex,
    required this.baseUrl,
    required this.tankName,
  });

  @override
  State<_PhotoViewScreen> createState() => _PhotoViewScreenState();
}

class _PhotoViewScreenState extends State<_PhotoViewScreen> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final photo = widget.photos[_currentIndex];
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          '${widget.tankName} · ${_currentIndex + 1}/${widget.photos.length}',
          style: const TextStyle(fontSize: 15),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: Text(
                _formatDate(photo['captured_at'] ?? ''),
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.photos.length,
        onPageChanged: (i) => setState(() => _currentIndex = i),
        itemBuilder: (ctx, i) {
          final url = '${widget.baseUrl}${widget.photos[i]['url']}';
          return InteractiveViewer(
            child: Center(
              child: CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.contain,
                placeholder: (_, __) => const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
                errorWidget: (_, __, ___) => const Center(
                  child: Icon(Icons.broken_image, color: Colors.white54, size: 64),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso);
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
          '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }
}
