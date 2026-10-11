import 'package:equatable/equatable.dart';
import '../models/customer_model.dart';

abstract class CustomerEvent extends Equatable {
  const CustomerEvent();

  @override
  List<Object?> get props => [];
}

class LoadCustomers extends CustomerEvent {
  final bool refresh;
  const LoadCustomers({this.refresh = false});

  @override
  List<Object?> get props => [refresh];
}

class AddCustomer extends CustomerEvent {
  final CustomerModel customer;
  const AddCustomer(this.customer);

  @override
  List<Object?> get props => [customer];
}

class UpdateCustomer extends CustomerEvent {
  final CustomerModel customer;
  const UpdateCustomer(this.customer);

  @override
  List<Object?> get props => [customer];
}

class DeleteCustomer extends CustomerEvent {
  final String id;
  const DeleteCustomer(this.id);

  @override
  List<Object?> get props => [id];
}
