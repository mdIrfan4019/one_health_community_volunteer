// import 'package:flutter/material.dart';
// import 'core/theme/app_colors.dart';
// import 'features/auth/presentation/screens/sign_in_screen.dart';

// void main() {
//   WidgetsFlutterBinding.ensureInitialized();
//   runApp(const CohvApp());
// }

// class CohvApp extends StatelessWidget {
//   const CohvApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'COHV Field Reporting',
//       debugShowCheckedModeBanner: false,
//       theme: ThemeData(
//         useMaterial3: true,
//         scaffoldBackgroundColor: AppColors.background,
//         colorScheme: ColorScheme.fromSeed(
//           seedColor: AppColors.primary,
//           primary: AppColors.primary,
//         ),
//       ),
//       home: const SignInScreen(),
//     );
//   }
// }


import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/theme/app_colors.dart';
import 'features/auth/presentation/screens/app_startup_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Make system status bar transparent and immersive (Edge-to-Edge)
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent, // Removes the straight top bar/border
      statusBarIconBrightness: Brightness.dark, // Dark icons (time, battery, wifi)
      statusBarBrightness: Brightness.light, // For iOS devices
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const CohvApp());
}

class CohvApp extends StatelessWidget {
  const CohvApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'COHV Field Reporting',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
        ),
      ),
      home: const AppStartupScreen(),
    );
  }
}
