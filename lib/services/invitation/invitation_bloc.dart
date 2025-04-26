// invitation_bloc.dart
import 'package:bloc/bloc.dart';
import 'package:naturafit/utilities/firebase_my_dictionary.dart';
import 'package:equatable/equatable.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// Events
abstract class InvitationEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class GenerateInvitation extends InvitationEvent {
  final String professionalId;
  final String professionalUsername;
  final String professionalFullName;
  final String role;
  final String? professionalProfileImageUrl;
  final String trainerClientId;

  GenerateInvitation({
    required this.professionalId,
    required this.professionalUsername,
    required this.professionalFullName,
    required this.role,
    this.professionalProfileImageUrl,
    required this.trainerClientId,
  });

  @override
  List<Object?> get props => [professionalId, professionalUsername, professionalFullName, role, professionalProfileImageUrl];
}

class ValidateInvitation extends InvitationEvent {
  final String code;
  final String currentUserRole;
  final String currentUserId;

  ValidateInvitation({
    required this.code,
    required this.currentUserRole,
    required this.currentUserId,
  });

  @override
  List<Object?> get props => [code, currentUserRole, currentUserId];
}

// States
abstract class InvitationState extends Equatable {
  @override
  List<Object?> get props => [];
}


class InvitationInitial extends InvitationState {}

class InvitationLoading extends InvitationState {}

class InvitationGenerated extends InvitationState {
  final String inviteCode;
  final String webLink;
  final String androidStoreLink;
  final String iOSStoreLink;

  InvitationGenerated({
    required this.inviteCode,
    required this.webLink,
    required this.androidStoreLink,
    required this.iOSStoreLink,
  });

  @override
  List<Object?> get props => [inviteCode, webLink, androidStoreLink, iOSStoreLink];
}

class InvitationValidated extends InvitationState {
  final Map<String, dynamic> inviteData;
  InvitationValidated(this.inviteData);

  @override
  List<Object?> get props => [inviteData];
}

class InvitationError extends InvitationState {
  final String message;
  InvitationError(this.message);

  @override
  List<Object?> get props => [message];
}

class InvitationBloc extends Bloc<InvitationEvent, InvitationState> {
  final FirebaseFirestore _firestore;

  static const String _webDomain = 'coachtrack.fit';
  static const String _androidStoreUrl =
      'https://play.google.com/store/apps/details?id=com.elephantmind.coachtrack';
  static const String _iOSStoreUrl =
      'https://apps.apple.com/app/coachtrack/idYOURAPPID';

  InvitationBloc({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        super(InvitationInitial()) {
    on<GenerateInvitation>(_onGenerateInvitation);
    on<ValidateInvitation>(_onValidateInvitation);
  }

  Future<void> _onGenerateInvitation(
    GenerateInvitation event,
    Emitter<InvitationState> emit,
  ) async {
    emit(InvitationLoading());

    debugPrint(
        'Generating invitation with professionalId: ${event.professionalId}');

    try {
      // Generate unique code
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final bytes = utf8.encode('${event.professionalId}-$timestamp');
      final hash = sha256.convert(bytes);
      final code = hash.toString().substring(0, 8);

      // Create web link
      final webLink =
          'https://$_webDomain/invite?code=$code&professional=${Uri.encodeComponent(event.professionalFullName ?? event.professionalUsername)}';

      // Store in Firestore with the code field
      await _firestore.collection('invites').doc(code).set({
        'code': code,
        'trainerClientId': event.trainerClientId,
        'professionalId': event.professionalId,
        'professionalUsername': event.professionalUsername,
        'professionalFullName': event.professionalFullName,
        fbProfileImageURL: event.professionalProfileImageUrl,
        'role': 'trainer',
        'timestamp': FieldValue.serverTimestamp(),
        'status': fbCreatedStatusForAppUser,
        'used': false,
        'webLink': webLink,
      });

      emit(InvitationGenerated(
        inviteCode: code,
        webLink: webLink,
        androidStoreLink: _androidStoreUrl,
        iOSStoreLink: _iOSStoreUrl,
      ));
    } catch (e) {
      emit(InvitationError(e.toString()));
    }
  }

  Future<void> _onValidateInvitation(
    ValidateInvitation event,
    Emitter<InvitationState> emit,
  ) async {
    emit(InvitationLoading());

    try {
      final inviteDoc =
          await _firestore.collection('invites').doc(event.code).get();

      if (!inviteDoc.exists) {
        emit(InvitationError('Invalid invitation code'));
        return;
      }

      final inviteData = inviteDoc.data()!;

      // Check if user is a professional (trainer or dietitian)
      if (event.currentUserRole == 'trainer' ||
          event.currentUserRole == 'dietitian') {
        emit(InvitationError('Professionals cannot accept client invitations'));
        return;
      }

      if (inviteData['used'] == true) {
        emit(InvitationError('This invitation has already been used'));
        return;
      }

      // Check for existing connection
      //final clientId = event.currentUserRole; // Get this from the validated user
      final professionalId = inviteData['professionalId'];

      final existingConnection = await _firestore
          .collection('connections')
          .doc('client')
          .collection(event.currentUserId)
          .doc(professionalId)
          .get();

      if (existingConnection.exists) {
        emit(InvitationError(
            'You already have a connection with this professional'));
        return;
      }

      emit(InvitationValidated(inviteData));
    } catch (e) {
      emit(InvitationError(e.toString()));
    }
  }
}
