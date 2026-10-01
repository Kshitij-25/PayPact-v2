import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get_it/get_it.dart';
import 'package:paypact/core/services/exchange_rate_service.dart';
import 'package:paypact/core/services/notification_service.dart';
import 'package:paypact/core/locale_cubit.dart';
import 'package:paypact/core/services/app_lock_service.dart';
import 'package:paypact/core/services/nudge_service.dart';
import 'package:paypact/core/services/telemetry_service.dart';
import 'package:paypact/core/services/photo_picker.dart';
import 'package:paypact/core/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:paypact/core/theme/theme_cubit.dart';
import 'package:paypact/features/activity/cubit/activity_cubit.dart';
import 'package:paypact/features/auth/data/account_service.dart';
import 'package:paypact/features/auth/data/repositories/firebase_auth_repository.dart';
import 'package:paypact/features/auth/domain/repositories/auth_repository.dart';
import 'package:paypact/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:paypact/features/expense/data/repositories/firestore_expense_repository.dart';
import 'package:paypact/features/expense/domain/repositories/expense_repository.dart';
import 'package:paypact/features/group/data/invite_service.dart';
import 'package:paypact/features/group/data/summary_service.dart';
import 'package:paypact/features/group/data/user_search_service.dart';
import 'package:paypact/features/group/data/repositories/firestore_group_repository.dart';
import 'package:paypact/features/group/domain/repositories/group_repository.dart';
import 'package:paypact/features/notification/data/repositories/firestore_notifications_repository.dart';
import 'package:paypact/features/notification/data/repositories/firestore_notification_prefs_repository.dart';
import 'package:paypact/features/notification/domain/repositories/notification_prefs_repository.dart';
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
  locator.registerLazySingleton<FirebaseFunctions>(
      () => FirebaseFunctions.instance);
  locator.registerLazySingleton<Dio>(() => Dio());

  final prefs = await SharedPreferences.getInstance();
  locator.registerSingleton<SharedPreferences>(prefs);

  // Services
  locator.registerLazySingleton<AppLockService>(
      () => AppLockService(locator<SharedPreferences>()));
  locator.registerLazySingleton<TelemetryService>(
      () => TelemetryService(locator<SharedPreferences>()));
  locator.registerLazySingleton<ExchangeRateService>(
      () => ExchangeRateService(locator<Dio>()));
  locator.registerLazySingleton<NotificationService>(() => NotificationService(
        locator<FirebaseMessaging>(),
        locator<FirebaseFirestore>(),
      ));

  locator.registerLazySingleton<FirebaseStorage>(
      () => FirebaseStorage.instance);
  locator.registerLazySingleton<StorageService>(
      () => StorageService(locator<FirebaseStorage>()));
  locator.registerLazySingleton<PhotoPicker>(() => PhotoPicker());
  locator.registerLazySingleton<SummaryService>(
      () => SummaryService(locator<FirebaseFunctions>()));
  locator.registerLazySingleton<UserSearchService>(
      () => UserSearchService(locator<FirebaseFunctions>()));
  locator.registerLazySingleton<InviteService>(
      () => InviteService(locator<FirebaseFunctions>()));

  locator.registerLazySingleton<AccountService>(
      () => AccountService(locator<fb.FirebaseAuth>(), locator<FirebaseFunctions>()));

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

  locator.registerLazySingleton<NotificationPrefsRepository>(
      () => FirestoreNotificationPrefsRepository(locator<FirebaseFirestore>()));

  locator.registerLazySingleton<NudgeService>(() => NudgeService(
        locator<NotificationsRepository>(),
        locator<SharedPreferences>(),
      ));

  // Cubits
  locator.registerLazySingleton<AuthCubit>(() => AuthCubit(
        locator<AuthRepository>(),
        onBeforeSignOut: locator<NotificationService>().clearToken,
      ));
  locator.registerLazySingleton<LocaleCubit>(
      () => LocaleCubit(locator<SharedPreferences>()));
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
