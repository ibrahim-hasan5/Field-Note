import 'package:equatable/equatable.dart';
import '../models/field_note_model.dart';

abstract class FieldNoteState extends Equatable {
  const FieldNoteState();

  @override
  List<Object?> get props => [];
}

class FieldNoteInitial extends FieldNoteState {}

class FieldNoteLoading extends FieldNoteState {}

class FieldNoteLoaded extends FieldNoteState {
  final List<FieldNoteModel> notes;

  const FieldNoteLoaded(this.notes);

  @override
  List<Object?> get props => [notes];
}

class FieldNoteError extends FieldNoteState {
  final String message;

  const FieldNoteError(this.message);

  @override
  List<Object?> get props => [message];
}
