// add_client_bloc.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:naturafit/services/user_provider.dart';
import 'package:naturafit/utilities/firebase_my_dictionary.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:provider/provider.dart';

// Events
abstract class EditClientEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class EditClient extends EditClientEvent {
  final Map<String, dynamic> data;
  final String professionalId;
  final String professionalRole;
  final BuildContext? context;
  final bool isClientInfoEnteredByTrainer;
  final bool isAppUser;

  EditClient({
    required this.data,
    required this.professionalId,
    required this.professionalRole,
    this.context,
    this.isClientInfoEnteredByTrainer = false,
    this.isAppUser = false,
  });

  @override
  List<Object?> get props => [data, professionalId, professionalRole, context, isAppUser, isClientInfoEnteredByTrainer];
}

// States
abstract class EditClientState extends Equatable {
  @override
  List<Object?> get props => [];
}

class EditClientInitial extends EditClientState {}

class EditClientLoading extends EditClientState {}

class EditClientSuccess extends EditClientState {
  final String? message;

  EditClientSuccess({this.message});

  @override
  List<Object?> get props => [message];
}

class EditClientError extends EditClientState {
  final String message;
  
  EditClientError(this.message);
  
  @override
  List<Object?> get props => [message];
}

class EditClientBloc extends Bloc<EditClientEvent, EditClientState> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  EditClientBloc() : super(EditClientInitial()) {
    on<EditClient>(_onEditClient);
  }

  Future<void> _onEditClient(
    EditClient event,
    Emitter<EditClientState> emit,
  ) async {
    try {
      emit(EditClientLoading());

      debugPrint('Editing client');
      // Validate required fields
      if (event.data['name']?.isEmpty ?? true) {
        throw Exception('Client name is required');
      }

      // Create a batch operation
      final batch = _firestore.batch();

      debugPrint('event.data: ${event.data}');
      // Get the client ID
      final clientId = event.data['clientId'];

      // Determine the reference based on whether it's an app user
      final clientRef = event.isAppUser 
          ? _firestore
              .collection('client_info')
              .doc(event.professionalRole)
              .collection(event.professionalId)
              .doc(clientId) 
          : _firestore
              .collection('connections')
              .doc(event.professionalRole)
              .collection(event.professionalId)
              .doc(clientId);

        

      // Prepare the edited client data with all fields
      final editedClientData = {
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
        'status': event.isAppUser ? fbClientConfirmedStatus : fbCreatedStatusForNotAppUser,
        'connectionType': event.isAppUser ? fbAppConnectionType : fbAddedManuallyConnectionType,
        'role': 'client',
        if (event.data['clientProfileImageUrl'] != null)
          'clientProfileImageUrl': event.data['clientProfileImageUrl'],
      };

      debugPrint('Updating client with data: $editedClientData');

      if (event.isClientInfoEnteredByTrainer) {
        // Update existing document
        debugPrint('Updating existing client info document');
        batch.update(clientRef, editedClientData);
      } else {
        // Create new document
        debugPrint('Creating new client info document');
        batch.set(clientRef, editedClientData);
      }

      // Commit the batch
      await batch.commit();

      emit(EditClientSuccess(
        message: 'Client ${event.isClientInfoEnteredByTrainer ? 'updated' : 'created'} successfully'
      ));
    } catch (e) {
      debugPrint('Error editing client: $e');
      emit(EditClientError(e.toString()));
    }
  }
}