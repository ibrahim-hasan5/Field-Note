import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/field_note_repository.dart';
import 'field_note_event.dart';
import 'field_note_state.dart';

class FieldNoteBloc extends Bloc<FieldNoteEvent, FieldNoteState> {
  final FieldNoteRepository _fieldNoteRepository;

  FieldNoteBloc({required FieldNoteRepository fieldNoteRepository})
      : _fieldNoteRepository = fieldNoteRepository,
        super(FieldNoteInitial()) {
    on<LoadFieldNotes>(_onLoadFieldNotes);
    on<AddFieldNote>(_onAddFieldNote);
    on<UpdateFieldNote>(_onUpdateFieldNote);
    on<DeleteFieldNote>(_onDeleteFieldNote);
  }

  Future<void> _onLoadFieldNotes(
    LoadFieldNotes event,
    Emitter<FieldNoteState> emit,
  ) async {
    emit(FieldNoteLoading());
    try {
      final notes = await _fieldNoteRepository.getNotes(
        siteId: event.siteId,
        status: event.status,
        searchQuery: event.searchQuery,
        refreshRemote: event.refresh,
      );
      emit(FieldNoteLoaded(notes));
    } catch (e, stack) {
      print('DEBUG ERROR in _onLoadFieldNotes: $e\n$stack');
      emit(FieldNoteError(e.toString()));
    }

  }

  Future<void> _onAddFieldNote(
    AddFieldNote event,
    Emitter<FieldNoteState> emit,
  ) async {
    try {
      await _fieldNoteRepository.saveNote(event.note);
      add(LoadFieldNotes(siteId: event.note.siteId, refresh: false));
    } catch (e) {
      emit(FieldNoteError(e.toString()));
    }
  }

  Future<void> _onUpdateFieldNote(
    UpdateFieldNote event,
    Emitter<FieldNoteState> emit,
  ) async {
    try {
      await _fieldNoteRepository.updateNote(event.note);
      add(LoadFieldNotes(siteId: event.note.siteId, refresh: false));
    } catch (e) {
      emit(FieldNoteError(e.toString()));
    }
  }

  Future<void> _onDeleteFieldNote(
    DeleteFieldNote event,
    Emitter<FieldNoteState> emit,
  ) async {
    try {
      await _fieldNoteRepository.deleteNote(event.id);
      add(LoadFieldNotes(siteId: event.siteId, refresh: false));
    } catch (e) {
      emit(FieldNoteError(e.toString()));
    }
  }
}
