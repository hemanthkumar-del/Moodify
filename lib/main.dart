import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/song_model.dart';
import 'models/playlist_model.dart';
import 'core/theme/app_theme.dart';
import 'providers/theme_provider.dart';
import 'providers/song_provider.dart';
import 'services/storage_service.dart';
import 'services/song_service.dart';
import 'services/audio_player_service.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive offline database
  await Hive.initFlutter();
  Hive.registerAdapter(SongModelAdapter());
  Hive.registerAdapter(PlaylistModelAdapter());
  
  await AudioPlayerService.initBackground();

  
  final storageService = StorageService();
  await storageService.init();

  final songService = SongService();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider(storageService)),
        ChangeNotifierProvider(create: (_) => SongProvider(songService, storageService)),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'Moodify',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.buildTheme(Brightness.light, themeProvider.primaryAccent),
      darkTheme: AppTheme.buildTheme(Brightness.dark, themeProvider.primaryAccent),
      themeMode: themeProvider.themeMode,
      home: const SplashScreen(),
    );
  }
}
