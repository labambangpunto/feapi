import 'package:flutter/material.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

void main() {
  runApp(const ComponentShowcaseApp());
}

class ComponentShowcaseApp extends StatefulWidget {
  const ComponentShowcaseApp({super.key});

  @override
  State<ComponentShowcaseApp> createState() => _ComponentShowcaseAppState();
}

class _ComponentShowcaseAppState extends State<ComponentShowcaseApp> {
  // 1. Fondasi Visual: State untuk menguji Light/Dark Mode
  ThemeMode _themeMode = ThemeMode.light;

  void toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.light
          ? ThemeMode.dark
          : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return M3ETheme(
      data: M3EThemeData(),
      child: MaterialApp(
        title: 'M3 Expressive Showcase',
        themeMode: _themeMode,
        // Tema Terang
        theme: ThemeData(
          fontFamily: 'SN Pro',
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.deepPurple,
            brightness: Brightness.light,
          ),
        ),
        // Tema Gelap
        darkTheme: ThemeData(
          fontFamily: 'SN Pro',
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.deepPurple,
            brightness: Brightness.dark,
          ),
        ),
        home: ShowcasePage(onThemeToggled: toggleTheme),
      ),
    );
  }
}

class ShowcasePage extends StatefulWidget {
  final VoidCallback onThemeToggled;
  const ShowcasePage({super.key, required this.onThemeToggled});

  @override
  State<ShowcasePage> createState() => _ShowcasePageState();
}

class _ShowcasePageState extends State<ShowcasePage> {
  // State untuk komponen Input & Form
  bool _obscurePassword = true;
  double _sliderValue = 50.0;
  bool _switchValue = true;
  bool _checkboxValue = false;
  int _radioValue = 1;
  int _navIndex = 0; // State Navigasi

  // Widget Helper untuk Judul Seksi
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w800,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      // 5. Navigasi: App Bar
      appBar: AppBar(
        title: const Text('M3 Expressive Showcase'),
        actions: [
          IconButton(
            icon: Icon(
              Theme.of(context).brightness == Brightness.light
                  ? Icons.dark_mode
                  : Icons.light_mode,
            ),
            onPressed: widget.onThemeToggled,
            tooltip: 'Toggle Theme',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // ==============================
          // 2. TIPOGRAFI
          // ==============================
          _buildSectionTitle('2. Tipografi'),
          Text('Display Large', style: textTheme.displayLarge),
          Text(
            'Headline Medium (Italic)',
            style: textTheme.headlineMedium?.copyWith(
              fontStyle: FontStyle.italic,
            ),
          ),
          Text(
            'Title Large (Bold 900)',
            style: textTheme.titleLarge?.copyWith(
              fontVariations: const [FontVariation('wght', 900)],
            ),
          ),
          Text(
            'Body Medium: Ini adalah paragraf standar untuk menguji line-height dan keterbacaan teks yang cukup panjang di dalam aplikasi. Material 3 memberikan spasi bernapas yang baik.',
            style: textTheme.bodyMedium,
          ),
          Text(
            'Label Small (Strikethrough)',
            style: textTheme.labelSmall?.copyWith(
              decoration: TextDecoration.lineThrough,
            ),
          ),
          const Divider(height: 32),

          // ==============================
          // 3. TOMBOL
          // ==============================
          _buildSectionTitle('3. Varian Tombol & State'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ElevatedButton(onPressed: () {}, child: const Text('Elevated')),
              FilledButton(onPressed: () {}, child: const Text('Filled')),
              FilledButton.tonal(onPressed: () {}, child: const Text('Tonal')),
              OutlinedButton(onPressed: () {}, child: const Text('Outlined')),
              TextButton(onPressed: () {}, child: const Text('Text')),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add),
                label: const Text('Ikon & Teks'),
              ),
              const ElevatedButton(
                onPressed: null,
                child: Text('Disabled'),
              ), // Disabled state
            ],
          ),
          const Divider(height: 32),

          // ==============================
          // 4. FORM & INPUT
          // ==============================
          _buildSectionTitle('4. Form & Input'),
          TextField(
            decoration: const InputDecoration(
              labelText: 'Email (Normal)',
              prefixIcon: Icon(Icons.email),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: 'Password (Toggle)',
              prefixIcon: const Icon(Icons.lock),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          const TextField(
            decoration: InputDecoration(
              labelText: 'Error State',
              errorText: 'Input tidak valid',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          // Pilihan (Switch, Checkbox, Radio)
          Row(
            children: [
              Switch(
                value: _switchValue,
                onChanged: (v) => setState(() => _switchValue = v),
              ),
              const Text('Switch'),
              const SizedBox(width: 16),
              Checkbox(
                value: _checkboxValue,
                onChanged: (v) => setState(() => _checkboxValue = v!),
              ),
              const Text('Checkbox'),
            ],
          ),
          Row(
            children: [
              Radio<int>(
                value: 1,
                groupValue: _radioValue,
                onChanged: (v) => setState(() => _radioValue = v!),
              ),
              const Text('Radio 1'),
              Radio<int>(
                value: 2,
                groupValue: _radioValue,
                onChanged: (v) => setState(() => _radioValue = v!),
              ),
              const Text('Radio 2'),
            ],
          ),
          Slider(
            value: _sliderValue,
            min: 0,
            max: 100,
            divisions: 5,
            label: _sliderValue.round().toString(),
            onChanged: (v) => setState(() => _sliderValue = v),
          ),
          const Divider(height: 32),

          // ==============================
          // 6. TAMPILAN DATA & 7. FEEDBACK
          // ==============================
          _buildSectionTitle('6 & 7. Data Display, Feedback, Loading'),
          Card(
            elevation: 4,
            child: ListTile(
              leading: const CircleAvatar(child: Text('M3')),
              title: const Text('Card & List Tile'),
              subtitle: const Text('Elevasi dan avatar dalam satu komponen.'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {},
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: [
              Chip(label: const Text('Chip Biasa'), onDeleted: () {}),
              ActionChip(
                label: const Text('Tampilkan Snackbar'),
                avatar: const Icon(Icons.message, size: 16),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Ini adalah Snackbar (Toast)!'),
                      action: SnackBarAction(label: 'Tutup', onPressed: () {}),
                    ),
                  );
                },
              ),
              ActionChip(
                label: const Text('Buka Dialog'),
                backgroundColor: colorScheme.errorContainer,
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Konfirmasi'),
                      content: const Text(
                        'Apakah Anda yakin ingin menghapus data ini? (Alert destruktif)',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Batal'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Hapus'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Expanded(child: LinearProgressIndicator()),
            ],
          ),
          const Divider(height: 32),

          // ==============================
          // 10. KASUS EKSTREM (EDGE CASES)
          // ==============================
          _buildSectionTitle('10. Edge Cases (Teks Panjang)'),
          Container(
            padding: const EdgeInsets.all(8),
            color: colorScheme.surfaceContainerHighest,
            child: const Text(
              'TeksSangatPanjangTanpaSpasiAaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
              overflow: TextOverflow.ellipsis, // Menguji Truncation (Ellipsis)
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Contoh angka besar: 1.234.567.890 | Karakter khusus: <script>, &, 🎉, é, 漢字',
          ),
          const SizedBox(height: 64), // Spasi ekstra untuk scroll
        ],
      ),

      // 3. Tombol (FAB)
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.edit),
      ),

      // 5. Navigasi (Bottom Bar)
      bottomNavigationBar: NavigationBar(
        selectedIndex: _navIndex,
        onDestinationSelected: (int index) {
          setState(() {
            _navIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Beranda'),
          NavigationDestination(icon: Icon(Icons.search), label: 'Cari'),
          NavigationDestination(
            icon: Icon(Icons.settings),
            label: 'Pengaturan',
          ),
        ],
      ),
    );
  }
}
