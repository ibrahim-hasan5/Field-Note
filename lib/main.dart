import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'core/di/injection_container.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/bloc/auth_bloc.dart';
import 'features/auth/bloc/auth_event.dart';
import 'features/auth/bloc/auth_state.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/customers/bloc/customer_bloc.dart';
import 'features/field_notes/bloc/field_note_bloc.dart';
import 'features/home/presentation/home_nav_screen.dart';
import 'features/settings/bloc/settings_bloc.dart';
import 'features/settings/bloc/settings_state.dart';
import 'features/settings/data/settings_repository.dart';
import 'features/sites/bloc/site_bloc.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize SharedPreferences Settings
  await SettingsRepository.init();

  // Set SQLite web factory ONCE here, before any DB is opened
  if (kIsWeb) {
    databaseFactory = databaseFactoryFfiWeb;
  }

  // Initialize Dependency Injection
  await initDependencies();

  runApp(const FieldNotesApp());
}

class FieldNotesApp extends StatelessWidget {
  const FieldNotesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<SettingsBloc>(
          create: (_) => SettingsBloc(settingsRepository: sl()),
        ),
        BlocProvider<AuthBloc>(
          create: (_) => AuthBloc(authRepository: sl())..add(AuthCheckRequested()),
        ),
        BlocProvider<CustomerBloc>(
          create: (_) => CustomerBloc(customerRepository: sl()),
        ),
        BlocProvider<SiteBloc>(
          create: (_) => SiteBloc(siteRepository: sl()),
        ),
        BlocProvider<FieldNoteBloc>(
          create: (_) => FieldNoteBloc(fieldNoteRepository: sl()),
        ),
      ],
      child: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, settingsState) {
          return MaterialApp(
            title: 'Field Notes',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: settingsState.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            home: const _AuthGate(),
          );
        },
      ),
    );
  }
}

class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is Authenticated) {
          return const HomeNavScreen();
        } else if (state is Unauthenticated) {
          return const LoginScreen();
        }
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
    );
  }
}
