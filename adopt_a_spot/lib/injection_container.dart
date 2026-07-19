import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:get_it/get_it.dart';
import 'domain/repositories/spot_repository.dart';
import 'domain/repositories/report_repository.dart';
import 'domain/repositories/user_repository.dart';
import 'domain/repositories/reward_repository.dart';
import 'domain/usecases/get_nearby_spots.dart';
import 'domain/usecases/adopt_spot.dart'; // AdoptSpotUseCase + CheckInUseCase
import 'domain/usecases/submit_report.dart';
import 'domain/usecases/redeem_coupon.dart';
import 'data/repositories/spot_repository_impl.dart';
import 'data/repositories/report_repository_impl.dart';
import 'data/repositories/user_repository_impl.dart';
import 'data/repositories/reward_repository_impl.dart';
import 'presentation/bloc/spot/spot_bloc.dart';
import 'presentation/bloc/report/report_bloc.dart';
import 'presentation/bloc/auth/auth_bloc.dart';
import 'presentation/bloc/points/points_bloc.dart';
import 'presentation/bloc/reward/reward_bloc.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // ── External ────────────────────────────────────────────────
  sl.registerLazySingleton(() => FirebaseFirestore.instance);
  sl.registerLazySingleton(() => FirebaseAuth.instance);
  sl.registerLazySingleton(() => FirebaseStorage.instance);
  sl.registerLazySingleton(() => FirebaseFunctions.instance);
  sl.registerLazySingleton(() => FirebaseMessaging.instance);

  // ── Repositories ────────────────────────────────────────────
  sl.registerLazySingleton<SpotRepository>(
    () => SpotRepositoryImpl(sl(), sl()),
  );
  sl.registerLazySingleton<ReportRepository>(
    () => ReportRepositoryImpl(sl(), sl(), sl()),
  );
  sl.registerLazySingleton<UserRepository>(
    () => UserRepositoryImpl(sl(), sl()),
  );
  sl.registerLazySingleton<RewardRepository>(
    () => RewardRepositoryImpl(sl(), sl()),
  );

  // ── Use Cases ────────────────────────────────────────────────
  sl.registerLazySingleton(() => GetNearbySpots(sl()));
  sl.registerLazySingleton(() => AdoptSpotUseCase(sl()));
  sl.registerLazySingleton(() => CheckInUseCase(sl()));
  sl.registerLazySingleton(() => SubmitReportUseCase(sl()));
  sl.registerLazySingleton(() => RedeemCouponUseCase(sl()));

  // ── BLoCs ────────────────────────────────────────────────────
  sl.registerFactory(() => SpotBloc(
        getNearbySpots: sl(),
        adoptSpot: sl(),
        checkIn: sl(),
        spotRepo: sl(),
      ));
  sl.registerFactory(() => ReportBloc(
        submitReport: sl(),
        storage: sl(),
      ));
  sl.registerFactory(() => AuthBloc(auth: sl(), userRepo: sl()));
  sl.registerFactory(() => PointsBloc(userRepo: sl()));
  sl.registerFactory(() => RewardBloc(redeemCoupon: sl(), rewardRepo: sl()));
}
