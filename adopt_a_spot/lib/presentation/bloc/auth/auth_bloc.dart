import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/repositories/user_repository.dart';

// ── Events ───────────────────────────────────────────────────
abstract class AuthEvent extends Equatable {
  @override List<Object?> get props => [];
}

class AuthStarted extends AuthEvent {}
class AuthSignedIn extends AuthEvent {
  final User user;
  AuthSignedIn(this.user);
  @override List<Object?> get props => [user.uid];
}
class AuthSignedOut extends AuthEvent {}
class AuthSignOutRequested extends AuthEvent {}

// ── States ───────────────────────────────────────────────────
abstract class AuthState extends Equatable {
  @override List<Object?> get props => [];
}

class AuthInitial extends AuthState {}
class AuthLoading extends AuthState {}
class AuthAuthenticated extends AuthState {
  final User user;
  AuthAuthenticated(this.user);
  @override List<Object?> get props => [user.uid];
}
class AuthUnauthenticated extends AuthState {}
class AuthError extends AuthState {
  final String message;
  AuthError(this.message);
  @override List<Object?> get props => [message];
}

// ── BLoC ─────────────────────────────────────────────────────
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final FirebaseAuth _auth;

  AuthBloc({required FirebaseAuth auth, required UserRepository userRepo})
      : _auth = auth,
        super(AuthInitial()) {
    on<AuthStarted>(_onStarted);
    on<AuthSignedIn>(_onSignedIn);
    on<AuthSignedOut>((_, emit) => emit(AuthUnauthenticated()));
    on<AuthSignOutRequested>(_onSignOut);

    // Listen to Firebase auth state changes
    _auth.authStateChanges().listen((user) {
      if (user != null) {
        add(AuthSignedIn(user));
      } else {
        add(AuthSignedOut());
      }
    });
  }

  Future<void> _onStarted(AuthStarted event, Emitter emit) async {
    emit(AuthLoading());
    final user = _auth.currentUser;
    if (user != null) {
      emit(AuthAuthenticated(user));
    } else {
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onSignedIn(AuthSignedIn event, Emitter emit) async {
    emit(AuthAuthenticated(event.user));
  }

  Future<void> _onSignOut(AuthSignOutRequested event, Emitter emit) async {
    await _auth.signOut();
    emit(AuthUnauthenticated());
  }
}
