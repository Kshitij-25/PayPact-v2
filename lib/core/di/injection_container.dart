import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get_it/get_it.dart';
import 'package:paypact/core/services/exchange_rate_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:paypact/core/theme/theme_cubit.dart';
import 'package:paypact/features/activity/cubit/activity_cubit.dart';
import 'package:paypact/features/auth/data/repositories/firebase_auth_repository.dart';
import 'package:paypact/features/auth/domain/repositories/auth_repository.dart';
import 'package:paypact/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:paypact/features/expense/data/repositories/firestore_expense_repository.dart';
import 'package:paypact/features/expense/domain/repositories/expense_repository.dart';
import 'package:paypact/features/group/data/repositories/firestore_group_repository.dart';
import 'package:paypact/features/group/domain/repositories/group_repository.dart';
import 'package:paypact/features/notification/data/repositories/firestore_notifications_repository.dart';
import 'package:paypact/features/notification/domain/repositories/notifications_repository.dart';
import 'package:paypact/features/profile/cubit/profile_cubit.dart';

final locator = GetIt.instance;

Future<void> initializeDependencies() async {
  // External
  locator.registerLazySingleton<fb.FirebaseAuth>(
      () => fb.FirebaseAuth.instance);
  locator.registerLazySingleton<FirebaseFirestore>(
      () => FirebaseFirestore.instance);
  locator.registerLazySingleton<FirebaseMessaging>(
      () => FirebaseMessaging.instance);
  locator.registerLazySingleton<Dio>(() => Dio());

  final prefs = await SharedPreferences.getInstance();
  locator.registerSingleton<SharedPreferences>(prefs);

  // Services
  locator.registerLazySingleton<ExchangeRateService>(
      () => ExchangeRateService(locator<Dio>()));

  // Repositories
  locator.registerLazySingleton<AuthRepository>(() => FirebaseAuthRepository(
        locator<fb.FirebaseAuth>(),
        locator<FirebaseFirestore>(),
      ));
  locator.registerLazySingleton<GroupRepository>(
      () => FirestoreGroupRepository(locator<FirebaseFirestore>()));
  locator.registerLazySingleton<ExpenseRepository>(
      () => FirestoreExpenseRepository(locator<FirebaseFirestore>()));
  locator.registerLazySingleton<NotificationsRepository>(
      () => FirestoreNotificationsRepository(locator<FirebaseFirestore>()));

  // Cubits
  locator.registerLazySingleton<AuthCubit>(
      () => AuthCubit(locator<AuthRepository>()));
  locator.registerLazySingleton<ThemeCubit>(
      () => ThemeCubit(locator<SharedPreferences>()));
  locator.registerFactory<ActivityCubit>(() => ActivityCubit(
        locator<GroupRepository>(),
        locator<ExpenseRepository>(),
      ));
  locator.registerFactory<ProfileCubit>(() => ProfileCubit(
        locator<FirebaseFirestore>(),
        locator<fb.FirebaseAuth>(),
        locator<GroupRepository>(),
      ));
}
