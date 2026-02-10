import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const String supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
    runApp(const MissingConfigApp());
    return;
  }

  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  runApp(const VideoApp());
}

class MissingConfigApp extends StatelessWidget {
  const MissingConfigApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Нужно передать --dart-define=SUPABASE_URL и --dart-define=SUPABASE_ANON_KEY',
              textAlign: TextAlign.center,
              style: GoogleFonts.manrope(fontSize: 18),
            ),
          ),
        ),
      ),
    );
  }
}

class VideoApp extends StatelessWidget {
  const VideoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'video_app',
      theme: ThemeData(
        brightness: Brightness.dark,
        textTheme: GoogleFonts.manropeTextTheme(),
        scaffoldBackgroundColor: const Color(0xFF070914),
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final _client = Supabase.instance.client;

  @override
  Widget build(BuildContext context) {
    final session = _client.auth.currentSession;
    if (session?.user != null) {
      return HomeScreen(user: session!.user);
    }
    return const LoginScreen();
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _client = Supabase.instance.client;

  bool _loading = false;
  String _message = '';

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _auth({required bool register}) async {
    setState(() {
      _loading = true;
      _message = '';
    });

    try {
      if (register) {
        await _client.auth.signUp(
          email: _email.text.trim(),
          password: _password.text,
        );
        setState(() => _message = 'Регистрация успешна. Теперь войдите.');
      } else {
        final response = await _client.auth.signInWithPassword(
          email: _email.text.trim(),
          password: _password.text,
        );
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => HomeScreen(user: response.user!)),
        );
      }
    } catch (e) {
      setState(() => _message = 'Ошибка: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A1F6A), Color(0xFF070914), Color(0xFF0F2B36)],
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Card(
              color: Colors.white.withValues(alpha: 0.09),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🎬 video_app',
                      style: GoogleFonts.manrope(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Войдите в систему для доступа к видеобиблиотеке.',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _email,
                      decoration: const InputDecoration(labelText: 'Email'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _password,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Пароль'),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: _loading ? null : () => _auth(register: false),
                          child: const Text('Войти'),
                        ),
                        const SizedBox(width: 10),
                        OutlinedButton(
                          onPressed: _loading ? null : () => _auth(register: true),
                          child: const Text('Регистрация'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (_loading) const LinearProgressIndicator(),
                    if (_message.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(_message),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class VideoCategory {
  VideoCategory({required this.id, required this.name});

  final String id;
  final String name;

  factory VideoCategory.fromMap(Map<String, dynamic> map) =>
      VideoCategory(id: map['id'] as String, name: map['name'] as String);
}

class VideoItem {
  VideoItem({
    required this.id,
    required this.title,
    required this.description,
    required this.thumbnailUrl,
    required this.videoUrl,
    required this.categoryId,
    required this.categoryName,
    required this.likes,
    required this.views,
  });

  final String id;
  final String title;
  final String? description;
  final String? thumbnailUrl;
  final String videoUrl;
  final String categoryId;
  final String categoryName;
  final int likes;
  final int views;

  factory VideoItem.fromMap(Map<String, dynamic> map) {
    final categoryMap = (map['video_categories'] as Map<String, dynamic>?);
    return VideoItem(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      thumbnailUrl: map['thumbnail_url'] as String?,
      videoUrl: map['video_url'] as String,
      categoryId: map['category_id'] as String,
      categoryName: (categoryMap?['name'] as String?) ?? 'Без категории',
      likes: (map['likes'] as num?)?.toInt() ?? 0,
      views: (map['views'] as num?)?.toInt() ?? 0,
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.user});

  final User user;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _client = Supabase.instance.client;
  final _search = TextEditingController();
  final _newCategory = TextEditingController();
  final _videoTitle = TextEditingController();
  final _videoDescription = TextEditingController();
  final _videoThumb = TextEditingController();
  final _videoUrl = TextEditingController();

  List<VideoCategory> _categories = [];
  List<VideoItem> _videos = [];
  String? _selectedCategoryId;
  String? _selectedCreateCategoryId;
  String _role = 'viewer';
  bool _loading = true;
  String _adminMessage = '';

  bool get _canManage =>
      _role == 'technical_lead' || _role == 'cmm_specialist';

  @override
  void initState() {
    super.initState();
    _loadAll();
    _search.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _search.dispose();
    _newCategory.dispose();
    _videoTitle.dispose();
    _videoDescription.dispose();
    _videoThumb.dispose();
    _videoUrl.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    try {
      final roleData = await _client
          .from('video_user_profiles')
          .select('role')
          .eq('user_id', widget.user.id)
          .maybeSingle();
      _role = (roleData?['role'] as String?) ?? 'viewer';

      final categoriesData = await _client
          .from('video_categories')
          .select('id,name')
          .order('name');
      _categories = (categoriesData as List)
          .map((e) => VideoCategory.fromMap(Map<String, dynamic>.from(e)))
          .toList();

      _selectedCreateCategoryId ??=
          _categories.isNotEmpty ? _categories.first.id : null;

      final videosData = await _client
          .from('video_items')
          .select(
            'id,title,description,thumbnail_url,video_url,category_id,likes,views,video_categories(name)',
          )
          .order('created_at', ascending: false);
      _videos = (videosData as List)
          .map((e) => VideoItem.fromMap(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      _adminMessage = 'Ошибка загрузки: $e';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _addCategory() async {
    if (_newCategory.text.trim().isEmpty) return;
    try {
      await _client
          .from('video_categories')
          .insert({'name': _newCategory.text.trim(), 'created_by': widget.user.id});
      _newCategory.clear();
      _adminMessage = 'Категория добавлена';
      await _loadAll();
    } catch (e) {
      setState(() => _adminMessage = 'Ошибка добавления категории: $e');
    }
  }

  Future<void> _addVideo() async {
    if (_videoTitle.text.trim().isEmpty ||
        _videoUrl.text.trim().isEmpty ||
        _selectedCreateCategoryId == null) {
      setState(() => _adminMessage = 'Заполните название, ссылку и категорию');
      return;
    }

    try {
      await _client.from('video_items').insert({
        'title': _videoTitle.text.trim(),
        'description': _videoDescription.text.trim(),
        'thumbnail_url': _videoThumb.text.trim(),
        'video_url': _videoUrl.text.trim(),
        'category_id': _selectedCreateCategoryId,
        'created_by': widget.user.id,
      });

      _videoTitle.clear();
      _videoDescription.clear();
      _videoThumb.clear();
      _videoUrl.clear();
      _adminMessage = 'Видео добавлено';
      await _loadAll();
    } catch (e) {
      setState(() => _adminMessage = 'Ошибка добавления видео: $e');
    }
  }

  Future<void> _logout() async {
    await _client.auth.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _videos.where((v) {
      final query = _search.text.trim().toLowerCase();
      final byQuery = query.isEmpty ||
          v.title.toLowerCase().contains(query) ||
          (v.description ?? '').toLowerCase().contains(query);
      final byCategory =
          _selectedCategoryId == null || v.categoryId == _selectedCategoryId;
      return byQuery && byCategory;
    }).toList();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0E1140), Color(0xFF070914), Color(0xFF0A2735)],
          ),
        ),
        child: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 14),
                      _buildSearchFilters(),
                      const SizedBox(height: 14),
                      if (_canManage) _buildAdminPanel(),
                      if (_canManage) const SizedBox(height: 14),
                      Expanded(
                        child: GridView.builder(
                          itemCount: filtered.length,
                          gridDelegate:
                              const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 380,
                            childAspectRatio: 0.85,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                          itemBuilder: (context, index) {
                            final v = filtered[index];
                            return _buildVideoCard(v);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Card(
      color: Colors.white.withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Лента видео',
                    style: GoogleFonts.manrope(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('Роль: $_role'),
                ],
              ),
            ),
            ElevatedButton(onPressed: _logout, child: const Text('Выйти')),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchFilters() {
    return Card(
      color: Colors.white.withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _search,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Поиск по названию и описанию',
                ),
              ),
            ),
            const SizedBox(width: 12),
            DropdownButton<String?>(
              value: _selectedCategoryId,
              hint: const Text('Все категории'),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('Все категории'),
                ),
                ..._categories.map(
                  (c) => DropdownMenuItem<String?>(
                    value: c.id,
                    child: Text(c.name),
                  ),
                ),
              ],
              onChanged: (value) => setState(() => _selectedCategoryId = value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminPanel() {
    return Card(
      color: Colors.white.withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Панель добавления (Technical Lead / CMM Specialist)',
              style: GoogleFonts.manrope(
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _newCategory,
                    decoration:
                        const InputDecoration(labelText: 'Новая категория'),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _addCategory,
                  child: const Text('Добавить категорию'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _videoTitle,
              decoration: const InputDecoration(labelText: 'Название видео'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _videoDescription,
              decoration: const InputDecoration(labelText: 'Описание'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _videoThumb,
              decoration: const InputDecoration(labelText: 'Ссылка на превью'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _videoUrl,
              decoration: const InputDecoration(labelText: 'Ссылка на видео'),
            ),
            const SizedBox(height: 8),
            DropdownButton<String>(
              value: _selectedCreateCategoryId,
              isExpanded: true,
              hint: const Text('Категория'),
              items: _categories
                  .map(
                    (c) => DropdownMenuItem<String>(
                      value: c.id,
                      child: Text(c.name),
                    ),
                  )
                  .toList(),
              onChanged: (value) =>
                  setState(() => _selectedCreateCategoryId = value),
            ),
            const SizedBox(height: 8),
            ElevatedButton(onPressed: _addVideo, child: const Text('Добавить видео')),
            if (_adminMessage.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(_adminMessage),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildVideoCard(VideoItem v) {
    return Card(
      color: Colors.white.withValues(alpha: 0.09),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Image.network(
                (v.thumbnailUrl?.isNotEmpty ?? false)
                    ? v.thumbnailUrl!
                    : 'https://images.unsplash.com/photo-1485846234645-a62644f84728?auto=format&fit=crop&w=1200&q=80',
                fit: BoxFit.cover,
                width: double.infinity,
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.black26,
                  alignment: Alignment.center,
                  child: const Icon(Icons.movie, size: 48),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  v.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text('${v.categoryName} • 👁 ${v.views} • 👍 ${v.likes}'),
                const SizedBox(height: 6),
                Text(
                  v.description ?? 'Без описания',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    FilledButton(
                      onPressed: () {},
                      child: const Text('Смотреть'),
                    ),
                    OutlinedButton(onPressed: () {}, child: const Text('Лайк')),
                    OutlinedButton(
                      onPressed: () {},
                      child: const Text('Поделиться'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}