// add_client_bloc.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:naturafit/services/user_provider.dart';
import 'package:naturafit/utilities/firebase_my_dictionary.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:provider/provider.dart';

// Events
abstract class AddClientEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class AddManualClient extends AddClientEvent {
  final Map<String, dynamic> data;
  final String professionalId;
  final String professionalRole;
  final BuildContext? context;

  AddManualClient({
    required this.data,
    required this.professionalId,
    required this.professionalRole,
    this.context,
  });

  @override
  List<Object?> get props => [data, professionalId, professionalRole, context];
}

class SendInvitation extends AddClientEvent {
  final String professionalId;
  final String professionalName;
  final String role;

  SendInvitation({
    required this.professionalId,
    required this.professionalName,
    required this.role,
  });

  @override
  List<Object?> get props => [professionalId, professionalName, role];
}

// States
abstract class AddClientState extends Equatable {
  @override
  List<Object?> get props => [];
}

class AddClientInitial extends AddClientState {}

class AddClientLoading extends AddClientState {}

class AddClientSuccess extends AddClientState {
  final String? message;

  AddClientSuccess({this.message});

  @override
  List<Object?> get props => [message];
}

class AddClientError extends AddClientState {
  final String message;
  
  AddClientError(this.message);
  
  @override
  List<Object?> get props => [message];
}

class AddClientBloc extends Bloc<AddClientEvent, AddClientState> {
  // You can add your repository or service here if needed
  // final ClientRepository _clientRepository;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AddClientBloc() : super(AddClientInitial()) {
    on<AddManualClient>(_onAddManualClient);
    on<SendInvitation>(_onSendInvitation);
  }

Future<void> _onAddManualClient(
    AddManualClient event,
    Emitter<AddClientState> emit,
  ) async {
    try {
      emit(AddClientLoading());

      debugPrint('Adding manual client');
      // Validate required fields
      if (event.data['name']?.isEmpty ?? true) {
        throw Exception('Client name is required');
      }

      /*
      if (event.data['email']?.isEmpty ?? true) {
        throw Exception('Email address is required');
      }

      // Validate email format
      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
      if (!emailRegex.hasMatch(event.data['email'])) {
        throw Exception('Invalid email format');
      }
      */

      // Create a batch operation
      final batch = _firestore.batch();

      // Generate a unique ID for the client
      final clientId = _firestore.collection('users').doc().id;

      // Add client to professional's connections collection
      final connectionRef = _firestore
          .collection('connections')
          .doc(event.professionalRole)
          .collection(event.professionalId)
          .doc(clientId);



      final addedClientData = {
        'clientId': clientId,
        'clientName': event.data['name'],
        'email': event.data['email'],
        'phone': event.data['phone'],
        'birthday': event.data['birthday'],
        'gender': event.data['gender'],
        'height': event.data['height'],
        'weight': event.data['weight'],
        'currentFitnessLevel': event.data['currentFitnessLevel'],
        'goals': event.data['goals'],
        'medicalHistory': event.data['medicalHistory'],
        'injuries': event.data['injuries'],
        'dietaryHabits': event.data['dietaryHabits'],
        'exercisePreferences': event.data['exercisePreferences'],
        'availableHours': event.data['availableHours'],
        'timestamp': FieldValue.serverTimestamp(),
        'status': fbCreatedStatusForNotAppUser,
        'connectionType': fbAddedManuallyConnectionType,
        'role': 'client',
        if (event.data['clientProfileImageUrl'] != null)
          'clientProfileImageUrl': event.data['clientProfileImageUrl'],
      };



      batch.set(connectionRef, addedClientData);

      // Commit the batch
      await batch.commit();

      // After successful addition, refresh the UserProvider data
      final userProvider = event.context?.read<UserProvider>();
      if (userProvider != null) {
        await userProvider.addManualPartiallyTotalClient(
          event.professionalId,
          event.professionalRole,
          addedClientData,
        );
      }

      emit(AddClientSuccess(message: 'Client added successfully'));
    } catch (e) {
      emit(AddClientError(e.toString()));
    }
  }

  Future<void> _onSendInvitation(
    SendInvitation event,
    Emitter<AddClientState> emit,
  ) async {
    try {
      emit(AddClientLoading());

      // Validate required fields
      if (event.professionalId.isEmpty) {
        throw Exception('Professional ID is required');
      }
      if (event.professionalName.isEmpty) {
        throw Exception('Professional name is required');
      }
      if (event.role.isEmpty) {
        throw Exception('Professional role is required');
      }

      // TODO: Add your invitation API call here
      // Example:
      // final response = await _clientRepository.sendInvitation({
      //   'professionalId': event.professionalId,
      //   'professionalName': event.professionalName,
      //   'role': event.role,
      //   'timestamp': DateTime.now().toIso8601String(),
      //   'status': 'pending',
      // });

      // Simulated API delay
      await Future.delayed(const Duration(seconds: 1));

      emit(AddClientSuccess(message: 'Invitation sent successfully'));
    } catch (e) {
      emit(AddClientError(e.toString()));
    }
  }
}