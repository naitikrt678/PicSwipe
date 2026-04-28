import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import '../state/app_state.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppState().init();
  runApp(const PhotoSwipeApp());
}

class PhotoSwipeApp extends StatelessWidget {
  const PhotoSwipeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppState(),
      builder: (context, child) {
        return MaterialApp(
          title: 'PhotoSwipe',
          theme: AppState().isDarkMode
              ? ThemeData(
                  brightness: Brightness.dark,
                  scaffoldBackgroundColor: Colors.black,
                  appBarTheme: const AppBarTheme(
                    backgroundColor: Colors.black,
                    elevation: 0,
                  ),
                  colorScheme: const ColorScheme.dark(
                    primary: Colors.white,
                    secondary: Colors.grey,
                  ),
                )
              : ThemeData.light(),
          home: const HomeScreen(),
        );
      },
    );
  }
}
