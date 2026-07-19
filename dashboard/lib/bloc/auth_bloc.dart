// dashboard/lib/bloc/auth_bloc.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

abstract class DashboardAuthEvent extends Equatable {
  @override List<Object?> get props => [];
}
class DashboardSignIn extends DashboardAuthEvent {}
class DashboardSignOut extends DashboardAuthEvent {}

abstract class DashboardAuthState extends Equatable {
  @override List<Object?> get props => [];
}
class DashboardAuthInitial extends DashboardAuthState {}
class DashboardAuthLoading extends DashboardAuthState {}
class DashboardAuthSuccess extends DashboardAuthState {
  final User user;
  DashboardAuthSuccess(this.user);
  @override List<Object?> get props => [user.uid];
}
class DashboardAuthFailed extends DashboardAuthState {
  final String message;
  DashboardAuthFailed(this.message);
  @override List<Object?> get props => [message];
}
class DashboardAuthSignedOut extends DashboardAuthState {}

class DashboardAuthBloc
    extends Bloc<DashboardAuthEvent, DashboardAuthState> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  DashboardAuthBloc() : super(DashboardAuthInitial()) {
    on<DashboardSignIn>(_onSignIn);
    on<DashboardSignOut>(_onSignOut);
  }

  Future<void> _onSignIn(
      DashboardSignIn event, Emitter emit) async {
    emit(DashboardAuthLoading());
    try {
      final provider = GoogleAuthProvider();
      final result = await _auth.signInWithPopup(provider);
      if (result.user != null) {
        // TODO: verify role == 'municipal' in Firestore
        emit(DashboardAuthSuccess(result.user!));
      } else {
        emit(DashboardAuthFailed('Sign-in failed'));
      }
    } catch (e) {
      emit(DashboardAuthFailed(e.toString()));
    }
  }

  Future<void> _onSignOut(
      DashboardSignOut event, Emitter emit) async {
    await _auth.signOut();
    emit(DashboardAuthSignedOut());
  }
}
