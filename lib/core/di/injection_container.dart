import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get_it/get_it.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:paypact/core/services/debt_simplification_service.dart';
import 'package:paypact/core/services/expense_split_service.dart';
import 'package:paypact/data/repositories/firebase_auth_repository.dart';
import 'package:paypact/data/repositories/firebase_expense_repository.dart';
import 'package:paypact/data/repositories/firebase_group_repository.dart';
import 'package:paypact/data/repositories/firebase_notification_repository.dart';
import 'package:paypact/domain/repositories/auth_repository.dart';
import 'package:paypact/domain/repositories/expense_repository.dart';
import 'package:paypact/domain/repositories/group_repository.dart';
import 'package:paypact/domain/repositories/notification_repository.dart';
import 'package:paypact/domain/use_cases/create_expense_use_case.dart';
import 'package:paypact/domain/use_cases/create_group_use_case.dart';
import 'package:paypact/domain/use_cases/delete_expense_use_case.dart';
import 'package:paypact/domain/use_cases/generate_invite_link_use_case.dart';
import 'package:paypact/domain/use_cases/get_current_user_use_case.dart';
import 'package:paypact/domain/use_cases/get_simplified_debts_use_case.dart';
import 'package:paypact/domain/use_cases/join_group_use_case.dart';
import 'package:paypact/domain/use_cases/record_settlement_use_case.dart';
import 'package:paypact/domain/use_cases/sign_in_with_google_use_case.dart';
import 'package:paypact/domain/use_cases/sign_out_use_case.dart';
import 'package:paypact/domain/use_cases/watch_auth_state_use_case.dart';
import 'package:paypact/domain/use_cases/watch_group_expenses_use_case.dart';
import 'package:paypact/domain/use_cases/watch_group_settlements_use_case.dart';
import 'package:paypact/domain/use_cases/watch_user_activity_use_case.dart';
import 'package:paypact/domain/use_cases/watch_user_groups_use_case.dart';
import 'package:paypact/presentation/bloc/auth_bloc/auth_bloc.dart';
import 'package:paypact/presentation/bloc/expense_bloc/expense_bloc.dart';
import 'package:paypact/presentation/bloc/group_bloc/group_bloc.dart';
import 'package:paypact/presentation/bloc/notification_bloc/notification_bloc.dart';

final locator = GetIt.instance;

Future<void> initializeDependencies() async {
  // ─── External ─────────────────────────────────────────────────────────────
  locator
      .registerLazySingleton<fb.FirebaseAuth>(() => fb.FirebaseAuth.instance);
  locator.registerLazySingleton<FirebaseFirestore>(
      () => FirebaseFirestore.instance);
  locator.registerLazySingleton<FirebaseMessaging>(
      () => FirebaseMessaging.instance);
  locator.registerLazySingleton<GoogleSignIn>(() => GoogleSignIn.instance);

  // ─── Domain Services ──────────────────────────────────────────────────────
  locator.registerLazySingleton<DebtSimplificationService>(
    () => const DebtSimplificationService(),
  );
  locator.registerLazySingleton<ExpenseSplitService>(
    () => const ExpenseSplitService(),
  );

  // ─── Repositories ─────────────────────────────────────────────────────────
  locator.registerLazySingleton<AuthRepository>(
    () => FirebaseAuthRepository(
      firebaseAuth: locator(),
      firestore: locator(),
      googleSignIn: locator(),
    ),
  );

  locator.registerLazySingleton<GroupRepository>(
    () => FirebaseGroupRepository(firestore: locator()),
  );

  locator.registerLazySingleton<ExpenseRepository>(
    () => FirebaseExpenseRepository(
      firestore: locator(),
      debtService: locator(),
    ),
  );

  locator.registerLazySingleton<NotificationRepository>(
    () => FirebaseNotificationRepository(messaging: locator()),
  );

  // ─── Auth Use Cases ───────────────────────────────────────────────────────
  locator.registerLazySingleton(() => SignInWithGoogleUseCase(locator()));
  locator.registerLazySingleton(() => SignOutUseCase(locator()));
  locator.registerLazySingleton(() => GetCurrentUserUseCase(locator()));
  locator.registerLazySingleton(() => WatchAuthStateUseCase(locator()));

  // ─── Group Use Cases ──────────────────────────────────────────────────────
  locator.registerLazySingleton(() => CreateGroupUseCase(locator()));
  locator.registerLazySingleton(() => WatchUserGroupsUseCase(locator()));
  locator.registerLazySingleton(() => JoinGroupUseCase(locator()));
  locator.registerLazySingleton(() => GenerateInviteLinkUseCase(locator()));

  // ─── Expense Use Cases ────────────────────────────────────────────────────
  locator
      .registerLazySingleton(() => CreateExpenseUseCase(locator(), locator()));
  locator.registerLazySingleton(() => WatchGroupExpensesUseCase(locator()));
  locator.registerLazySingleton(() => DeleteExpenseUseCase(locator()));
  locator.registerLazySingleton(() => GetSimplifiedDebtsUseCase(locator()));
  locator.registerLazySingleton(() => WatchGroupSettlementsUseCase(locator()));
  locator.registerLazySingleton(() => WatchUserActivityUseCase(locator()));

  // ─── Settlement Use Cases ─────────────────────────────────────────────────
  locator.registerLazySingleton(() => RecordSettlementUseCase(locator()));

  // ─── BLoCs ────────────────────────────────────────────────────────────────
  locator.registerFactory(
    () => AuthBloc(
      watchAuthState: locator(),
      signInWithGoogle: locator(),
      signOut: locator(),
      getCurrentUser: locator(),
    ),
  );

  locator.registerFactory(
    () => GroupBloc(
      watchUserGroups: locator(),
      createGroup: locator(),
      joinGroup: locator(),
      generateInviteLink: locator(),
    ),
  );

  locator.registerFactory(
    () => ExpenseBloc(
      watchUserActivity: locator(),
      watchGroupExpenses: locator(),
      createExpense: locator(),
      deleteExpense: locator(),
      getSimplifiedDebts: locator(),
      recordSettlement: locator(),
      watchGroupSettlements: locator(),
    ),
  );

  locator.registerFactory(
      () => NotificationBloc(notificationRepository: locator()));
}
