import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/customer_repository.dart';
import 'customer_event.dart';
import 'customer_state.dart';

class CustomerBloc extends Bloc<CustomerEvent, CustomerState> {
  final CustomerRepository _customerRepository;

  CustomerBloc({required CustomerRepository customerRepository})
      : _customerRepository = customerRepository,
        super(CustomerInitial()) {
    on<LoadCustomers>(_onLoadCustomers);
    on<AddCustomer>(_onAddCustomer);
    on<UpdateCustomer>(_onUpdateCustomer);
    on<DeleteCustomer>(_onDeleteCustomer);
  }

  Future<void> _onLoadCustomers(
    LoadCustomers event,
    Emitter<CustomerState> emit,
  ) async {
    emit(CustomerLoading());
    try {
      final customers = await _customerRepository.getCustomers(
        refreshRemote: event.refresh,
      );
      emit(CustomerLoaded(customers));
    } catch (e) {
      emit(CustomerError(e.toString()));
    }
  }

  Future<void> _onAddCustomer(
    AddCustomer event,
    Emitter<CustomerState> emit,
  ) async {
    try {
      await _customerRepository.saveCustomer(event.customer);
      add(const LoadCustomers(refresh: false));
    } catch (e) {
      emit(CustomerError(e.toString()));
    }
  }

  Future<void> _onUpdateCustomer(
    UpdateCustomer event,
    Emitter<CustomerState> emit,
  ) async {
    try {
      await _customerRepository.updateCustomer(event.customer);
      add(const LoadCustomers(refresh: false));
    } catch (e) {
      emit(CustomerError(e.toString()));
    }
  }

  Future<void> _onDeleteCustomer(
    DeleteCustomer event,
    Emitter<CustomerState> emit,
  ) async {
    try {
      await _customerRepository.deleteCustomer(event.id);
      add(const LoadCustomers(refresh: false));
    } catch (e) {
      emit(CustomerError(e.toString()));
    }
  }
}
