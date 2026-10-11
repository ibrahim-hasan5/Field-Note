import 'package:equatable/equatable.dart';
import '../models/field_note_model.dart';

abstract class FieldNoteEvent extends Equatable {
  const FieldNoteEvent();

  @override
  List<Object?> get props => [];
}

class LoadFieldNotes extends FieldNoteEvent {
  final String? siteId;
  final String? status;
  final String? searchQuery;
  final bool refresh;

  const LoadFieldNotes({
    this.siteId,
    this.status,
    this.searchQuery,
    this.refresh = false,
  });

  @override
  List<Object?> get props => [siteId, status, searchQuery, refresh];
}

class AddFieldNote extends FieldNoteEvent {
  final FieldNoteModel note;
  const AddFieldNote(this.note);

  @override
  List<Object?> get props => [note];
}

class UpdateFieldNote extends FieldNoteEvent {
  final FieldNoteModel note;
  const UpdateFieldNote(this.note);

  @override
  List<Object?> get props => [note];
}

class DeleteFieldNote extends FieldNoteEvent {
  final String id;
  final String? siteId;

  const DeleteFieldNote(this.id, {this.siteId});

  @override
  List<Object?> get props => [id, siteId];
}
