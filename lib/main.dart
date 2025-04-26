import 'package:naturafit/services/auth/bloc/data_fetch_service.dart';
import 'package:naturafit/services/auth/bloc/my_auth_bloc.dart';
import 'package:naturafit/services/deep_link_service.dart';
import 'package:naturafit/services/invitation/connections_bloc.dart';
import 'package:naturafit/services/invitation/invitation_bloc.dart';
import 'package:naturafit/services/stripe_service.dart';
import 'package:naturafit/services/user_provider.dart';
import 'package:naturafit/utilities/color_scheme.dart';
import 'package:naturafit/utilities/platform_check.dart';
import 'package:naturafit/views/all_shared_settings/privacy_policy_page.dart';
import 'package:naturafit/views/auth_side/select_role_page.dart';
import 'package:naturafit/views/auth_side/welcome_page.dart';
import 'package:naturafit/views/client_side/client_side.dart';
import 'package:naturafit/views/trainer_side/coach_side.dart';
import 'package:naturafit/services/firebase_service.dart';
import 'package:naturafit/views/web/web_client_side.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'package:naturafit/services/theme_provider.dart';
import 'package:naturafit/utilities/theme_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:naturafit/services/unit_preferences.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:naturafit/services/locale_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:naturafit/views/web/landing_page.dart';
import 'package:naturafit/views/web/web_coach_side.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';



//flutter build web --release
//firebase deploy
//flutter run -d chrome







void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize SharedPreferences for theme persistence
  try {
    await SharedPreferences.getInstance();
    debugPrint('SharedPreferences initialized successfully');
  } catch (e) {
    debugPrint('SharedPreferences initialization error: $e');
  }
  
  // First initialize Firebase with error handling
  try {
    debugPrint('Attempting to initialize Firebase...');
    final options = DefaultFirebaseOptions.currentPlatform;
    debugPrint('Firebase options loaded: ${options.projectId}');
    
    await Firebase.initializeApp(
      options: options,
    );
    debugPrint('Firebase initialized successfully');
  } catch (e, stackTrace) {
    debugPrint('Firebase initialization error: $e');
    debugPrint('Stack trace: $stackTrace');
  }

  // Comment out Stripe for now
  /*
  try {
    await StripeService.initialize();
  } catch (e) {
    debugPrint('Stripe initialization error: $e');
  }
  */

  debugPrint('Creating services...');
  final firebaseService = FirebaseService();
  final userProvider = UserProvider();
  final deepLinkService = DeepLinkService();
  final dataFetchService = DataFetchService();

  debugPrint('Starting app...');

  if (!kIsWeb) {
    // Only force portrait mode on mobile devices
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => userProvider),
        BlocProvider(
          create: (_) => AuthBloc(
            firebaseService: firebaseService,
            dataFetchService: dataFetchService,
          ),
        ),
        BlocProvider(create: (_) => InvitationBloc()),
        BlocProvider(create: (_) => ConnectionsBloc()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => UnitPreferences()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
      ],
      child: MyApp(deepLinkService: deepLinkService),
    ),
  );
}

class MyApp extends StatefulWidget {
  final DeepLinkService deepLinkService;
  final Locale? locale;
  
  const MyApp({
    super.key,
    required this.deepLinkService,
    this.locale,
  });

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    
    if (!kIsWeb) { // Only initialize deep links for mobile
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.deepLinkService.initDeepLinks(context);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          navigatorKey: widget.deepLinkService.navigationKey,
          scaffoldMessengerKey: GlobalKey<ScaffoldMessengerState>(),
          debugShowCheckedModeBanner: false,
          title: 'NaturaFit',
          theme: ThemeConfig.lightTheme,
          darkTheme: ThemeConfig.darkTheme,
          themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          themeAnimationDuration: ThemeProvider.themeAnimationDuration,
          themeAnimationCurve: ThemeProvider.themeAnimationCurve,
          locale: context.watch<LocaleProvider>().locale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          initialRoute: '/',
          routes: {
            '/': (context) {
              debugPrint('==== ROUTE: / ====');
              if (kIsWeb) {
                final uri = Uri.parse(Uri.base.toString());
                final path = uri.path.toLowerCase();
                debugPrint('Current URL path: $path');
                
                if (path.contains('privacypolicy')) {
                  debugPrint('Serving Privacy Policy page');
                  return const PrivacyPolicyPage(showBackButton: false);
                }
                return const AuthCheck();
              }
              return const AuthCheck();
            },
            '/privacypolicy': (context) {
              debugPrint('==== ROUTE: /privacypolicy ====');
              return const PrivacyPolicyPage(showBackButton: false);
            },
          },
          // Comment out onGenerateRoute temporarily
          /*onGenerateRoute: (settings) {
            print('==== ROUTE SETTINGS ====');
            print('Incoming route: ${settings.name}');
            if (kIsWeb) {
              print('Platform: Web');
              // Get the full URL path
              final uri = Uri.parse(settings.name ?? '');
              final path = uri.path.toLowerCase();
              print('Parsed URI path: $path');
              
              // Check if the path contains 'privacypolicy' anywhere in the URL
              if (path.contains('privacypolicy')) {
                print('Routing to Privacy Policy page');
                return MaterialPageRoute(
                  builder: (context) => const PrivacyPolicyPage(showBackButton: false),
                );
              }
              
              // Handle root path
              if (path == '/' || path.isEmpty) {
                print('Routing to Auth Check (root path)');
                return MaterialPageRoute(
                  builder: (context) => const AuthCheck(),
                );
              }
              
              // For any other web routes, show the landing page
              print('Routing to Landing Page (default web route)');
              return MaterialPageRoute(
                builder: (context) => const LandingPage(),
              );
            } else {
              print('Platform: Mobile');
              // Mobile routing remains the same
              switch (settings.name) {
                case '/privacypolicy':
                  print('Routing to Privacy Policy page (mobile)');
                  return MaterialPageRoute(
                    builder: (context) => const PrivacyPolicyPage(showBackButton: false),
                  );
                case '/':
                  print('Routing to Auth Check (mobile root)');
                  return MaterialPageRoute(
                    builder: (context) => const AuthCheck(),
                  );
                default:
                  print('Routing to Auth Check (mobile default)');
                  return MaterialPageRoute(
                    builder: (context) => const AuthCheck(),
                  );
              }
            }
          },*/
          supportedLocales: const [
            Locale('en'), // English
            Locale('tr'), // Turkish
            Locale('de'), // German
            Locale('es'), // Spanish
            Locale('fr'), // French
            Locale('it'), // Italian
            Locale('pt'), // Portuguese
            // ... other locales ...
          ],
        );
      },
    );
  }
}

class AuthCheck extends StatelessWidget {
  const AuthCheck({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is AuthInitial) {
          context.read<AuthBloc>().add(CheckAuthStatus(context));
        }

        if (state is AuthLoading) {
          
          Future.delayed(const Duration(seconds: 15), () {
            if (context.mounted &&
                context.read<AuthBloc>().state is AuthLoading) {
              context.read<AuthBloc>().add(AuthenticationFailed());
            }
          });

          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: myBlue60),
                  const SizedBox(height: 16),
                  Text('Loading...',
                      style: GoogleFonts.plusJakartaSans(fontSize: 16, color: theme.brightness == Brightness.light ? myGrey60 : myGrey40)),
                ],
              ),
            ),
          );
        }

        if (state is AuthError) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error occurred',
                      style: GoogleFonts.plusJakartaSans(fontSize: 18, color: Colors.red)),
                  const SizedBox(height: 8),
                  Text(state.message,
                      style: GoogleFonts.plusJakartaSans(fontSize: 14, color: theme.brightness == Brightness.light ? myGrey90 : myGrey40)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<AuthBloc>().add(CheckAuthStatus());
                    },
                    child: Text('Retry',
                        style: GoogleFonts.plusJakartaSans(fontSize: 14, color: theme.brightness == Brightness.light ? myGrey90 : myGrey40)),
                  ),
                ],
              ),
            ),
          );
        }

        if (state is AuthAuthenticated) {
          context.read<UserProvider>().setUserData(state.userData);

          debugPrint('state.userId: ${state.userData['userId']}');
          debugPrint('state.role: ${state.role}');
          debugPrint('state.userData: ${state.userData}');

          if (state.role == '') {
            return UserTypeScreen(passedUserId: state.userData['userId']);
          }


          if (isWebOrDesktopCached != null && isWebOrDesktopCached == true) {
            switch (state.role) {
              case 'trainer':
                return const WebCoachSide();
              case 'client':
                return const WebClientSide();
              default:
                return const LandingPage();
            }
          } else {
            switch (state.role) {
              case 'trainer':
                return const CoachSide();
              case 'client':
                return const ClientSide();
              default:
                return const WelcomeScreen();
            }
          }
        }

        return kIsWeb ? const LandingPage() : const WelcomeScreen();
      },
    );
  }
}
