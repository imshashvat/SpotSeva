// dashboard/lib/bloc/dashboard_bloc.dart — stub for dashboard state
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

abstract class DashboardEvent extends Equatable {
  @override List<Object?> get props => [];
}
class LoadOverview extends DashboardEvent {}
class LoadReports extends DashboardEvent {
  final String? statusFilter;
  final String? severityFilter;
  LoadReports({this.statusFilter, this.severityFilter});
}

abstract class DashboardState extends Equatable {
  @override List<Object?> get props => [];
}
class DashboardInitial extends DashboardState {}
class DashboardLoading extends DashboardState {}
class DashboardError extends DashboardState {
  final String message;
  DashboardError(this.message);
  @override List<Object?> get props => [message];
}

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  DashboardBloc() : super(DashboardInitial()) {
    on<LoadOverview>((_, emit) => emit(DashboardLoading()));
    on<LoadReports>((_, emit) => emit(DashboardLoading()));
  }
}
