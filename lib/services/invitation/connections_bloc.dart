// connections_bloc.dart
import 'package:naturafit/utilities/firebase_my_dictionary.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Events
abstract class ConnectionEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class AcceptInvitation extends ConnectionEvent {
  final String clientId;
  final String clientName;
  final String professionalId;
  final String professionalRole;
  final String professionalUsername;
  final String professionalFullName;
  final String? clientProfileImageUrl;
  final String? professionalProfileImageUrl;

  AcceptInvitation({
    required this.clientId,
    required this.clientName,
    required this.professionalId,
    required this.professionalRole,
    required this.professionalUsername,
    required this.professionalFullName,
    this.clientProfileImageUrl,
    this.professionalProfileImageUrl,
  });

  @override
  List<Object?> get props => [clientId, professionalId, professionalRole, professionalUsername, professionalFullName];
}

// States
abstract class ConnectionsState extends Equatable {
  @override
  List<Object?> get props => [];
}

class ConnectionsInitial extends ConnectionsState {}
class ConnectionsLoading extends ConnectionsState {}
class ConnectionsSuccess extends ConnectionsState {}
class ConnectionsError extends ConnectionsState {
  final String message;
  ConnectionsError(this.message);

  @override
  List<Object?> get props => [message];
}

class ConnectionsBloc extends Bloc<ConnectionEvent, ConnectionsState> {
  final FirebaseFirestore _firestore;

  ConnectionsBloc({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        super(ConnectionsInitial()) {
    on<AcceptInvitation>(_onAcceptInvitation);
  }

  Future<void> _onAcceptInvitation(
    AcceptInvitation event,
    Emitter<ConnectionsState> emit,
  ) async {
    emit(ConnectionsLoading());

    try {
      // Create batch for atomic operations
      final batch = _firestore.batch();

      // Update professional's connections
      final professionalRef = _firestore
          .collection('connections')
          .doc(event.professionalRole)
          .collection(event.professionalId)
          .doc(event.clientId);

      batch.set(professionalRef, {
        'clientId': event.clientId,
        'clientName': event.clientName,
        'clientProfileImageUrl': event.clientProfileImageUrl,
        'timestamp': FieldValue.serverTimestamp(),
        'lastActivity': FieldValue.serverTimestamp(),
        'status': fbClientConfirmedStatus,
        'role': 'client',
        'connectionType': fbAppConnectionType,
      });

      // Update client's connections
      final clientRef = _firestore
          .collection('connections')
          .doc('client')
          .collection(event.clientId)
          .doc(event.professionalId);

      batch.set(clientRef, {
        'professionalId': event.professionalId,
        'professionalUsername': event.professionalUsername,
        'professionalFullName': event.professionalFullName,
        'professionalProfileImageUrl': event.professionalProfileImageUrl,
        'role': event.professionalRole,
        'timestamp': FieldValue.serverTimestamp(),
        'lastActivity': FieldValue.serverTimestamp(),
        'status': fbClientConfirmedStatus,
        'connectionType': fbAppConnectionType,
      });

      await batch.commit();
      emit(ConnectionsSuccess());
    } catch (e) {
      emit(ConnectionsError(e.toString()));
    }
  }
}