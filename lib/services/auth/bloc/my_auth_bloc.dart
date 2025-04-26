import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:naturafit/services/auth/bloc/data_fetch_service.dart';
import 'package:naturafit/services/firebase_service.dart';
import 'package:naturafit/utilities/platform_check.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:naturafit/services/user_provider.dart';

// Events
abstract class AuthEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class CheckAuthStatus extends AuthEvent {
  final BuildContext? context;
  CheckAuthStatus([this.context]);

  @override
  List<Object?> get props => [context];
}

class AuthLogout extends AuthEvent {
  final BuildContext context;
  AuthLogout(this.context);

  @override
  List<Object?> get props => [context];
}

class AuthenticationFailed extends AuthEvent {}

// States
abstract class AuthState extends Equatable {
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthError extends AuthState {
  final String message;
  AuthError(this.message);

  @override
  List<Object?> get props => [message];
}

class AuthAuthenticated extends AuthState {
  final String role;
  final Map<String, dynamic> userData;

  AuthAuthenticated(this.role, this.userData);

  @override
  List<Object?> get props => [role, userData];
}

class AuthUnauthenticated extends AuthState {}

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final FirebaseService firebaseService;
  final DataFetchService dataFetchService;

  AuthBloc({
    required this.firebaseService,
    required this.dataFetchService,
  }) : super(AuthInitial()) {
    on<CheckAuthStatus>(_onCheckAuthStatus);
    on<AuthLogout>(_onAuthLogout);
    on<AuthenticationFailed>(_onAuthenticationFailed);
  }

  Future<void> _onCheckAuthStatus(
    CheckAuthStatus event,
    Emitter<AuthState> emit,
  ) async {
    debugPrint('Auth check called from: ${StackTrace.current}');
    emit(AuthLoading());

    try {
      // Do platform checks in parallel
      await Future.wait([
        isMobileWeb(),
        isMobile(),
        isWebOrDesktop(),
      ]);
      
      debugPrint('Starting auth status check');
      final userId = firebaseService.getCurrentUserId();
      debugPrint('UserId from Firebase: ${userId ?? 'null'}');

      if (userId == null) {
        debugPrint('No userId found in Firebase, emitting unauthenticated');
        emit(AuthUnauthenticated());
        return;
      }

      debugPrint('Fetching user data for userId: $userId');
      final userData = await firebaseService.getUserData(userId);
      debugPrint('Received userData: ${userData?.toString() ?? 'null'}');
      debugPrint('myDataUserId: ${userData?['userId'] ?? 'null'}');
      debugPrint('myDataTrainerClientId: ${userData?['trainerClientId'] ?? 'null'}');

      final role = userData?['role'] as String?;
      debugPrint('User role: ${role ?? 'null'}');

      if (role == null) {
        debugPrint('No role found in userData, emitting unauthenticated');
        emit(AuthUnauthenticated());
        return;
      }

      if (event.context != null && event.context!.mounted) {
        final userProvider = Provider.of<UserProvider>(event.context!, listen: false);
        userProvider.setUserData(userData);

        try {
          await dataFetchService.fetchUserData(userId, role, event.context!);
        } catch (e) {
          debugPrint('Error fetching data: $e');
          // Continue with authentication even if fetch fails
        }


      }

      debugPrint('Authentication successful, emitting authenticated state');
      emit(AuthAuthenticated(role, userData!));
    } catch (e, stackTrace) {
      debugPrint('Error during auth check: $e');
      debugPrint('Stack trace: $stackTrace');
      emit(AuthError('Authentication failed: ${e.toString()}'));
      await Future.delayed(const Duration(seconds: 2));
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onAuthLogout(
    AuthLogout event,
    Emitter<AuthState> emit,
  ) async {
    debugPrint('Processing logout');
    try {
      // Get current user ID from Firebase
      final userId = firebaseService.getCurrentUserId();

      if (userId != null) {
        // Update Firestore logout status
        await firebaseService.logoutUser(userId);
      }

      // Clear local storage
      //await firebaseService.deleteUserIdLocally();
      debugPrint('Local user data deleted');

      // Clear UserProvider data
      if (event.context.mounted) {
        Provider.of<UserProvider>(event.context, listen: false).clearAllData();
        debugPrint('UserProvider data cleared');
      }

      emit(AuthUnauthenticated());
    } catch (e) {
      debugPrint('Error during logout: $e');
      emit(AuthError('Logout failed: ${e.toString()}'));
      await Future.delayed(const Duration(seconds: 2));
      emit(AuthUnauthenticated());
    }
  }

  void _onAuthenticationFailed(
    AuthenticationFailed event,
    Emitter<AuthState> emit,
  ) {
    debugPrint('Authentication timed out or failed');
    emit(AuthUnauthenticated());
  }
}
