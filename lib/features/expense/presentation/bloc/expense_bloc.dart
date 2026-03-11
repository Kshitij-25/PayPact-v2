import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:paypact/features/expense/domain/entities/expense_entity.dart';
import 'package:paypact/features/expense/domain/entities/settlement_entity.dart';
import 'package:paypact/features/expense/domain/use_cases/create_expense_use_case.dart';
import 'package:paypact/features/expense/domain/use_cases/delete_expense_use_case.dart';
import 'package:paypact/features/expense/domain/use_cases/record_settlement_use_case.dart';
import 'package:paypact/features/expense/domain/use_cases/update_expense_use_case.dart';
import 'package:paypact/features/group/domain/entities/debt_entity.dart';
import 'package:paypact/features/group/domain/use_cases/get_simplified_debts_use_case.dart';
import 'package:paypact/features/group/domain/use_cases/watch_group_expenses_use_case.dart';
import 'package:paypact/features/group/domain/use_cases/watch_group_settlements_use_case.dart';
import 'package:paypact/features/home/domain/use_cases/watch_user_activity_use_case.dart';

part 'expense_event.dart';
part 'expense_state.dart';

class ExpenseBloc extends Bloc<ExpenseEvent, ExpenseState> {
  ExpenseBloc({
    required WatchGroupExpensesUseCase watchGroupExpenses,
    required WatchGroupSettlementsUseCase watchGroupSettlements,
    required WatchUserActivityUseCase watchUserActivity,
    required CreateExpenseUseCase createExpense,
    required UpdateExpenseUseCase updateExpense,
    required DeleteExpenseUseCase deleteExpense,
    required GetSimplifiedDebtsUseCase getSimplifiedDebts,
    required RecordSettlementUseCase recordSettlement,
  })  : _watchGroupExpenses = watchGroupExpenses,
        _watchGroupSettlements = watchGroupSettlements,
        _watchUserActivity = watchUserActivity,
        _createExpense = createExpense,
        _updateExpense = updateExpense,
        _deleteExpense = deleteExpense,
        _getSimplifiedDebts = getSimplifiedDebts,
        _recordSettlement = recordSettlement,
        super(const ExpenseState()) {
    on<ExpenseLoadRequested>(_onLoad);
    on<ActivityLoadRequested>(_onActivityLoad);
    on<ExpenseCreateRequested>(_onCreate);
    on<ExpenseUpdateRequested>(_onUpdate);
    on<ExpenseDeleteRequested>(_onDelete);
    on<ExpenseDebtsRequested>(_onDebts);
    on<ExpenseSettlementRequested>(_onSettle);
    on<_ExpenseListUpdated>(_onListUpdated);
    on<_SettlementListUpdated>(_onSettlementListUpdated);
    on<_ActivityExpensesUpdated>(_onActivityExpensesUpdated);
    on<_ActivitySettlementsUpdated>(_onActivitySettlementsUpdated);
  }

  final WatchGroupExpensesUseCase _watchGroupExpenses;
  final WatchGroupSettlementsUseCase _watchGroupSettlements;
  final WatchUserActivityUseCase _watchUserActivity;
  final CreateExpenseUseCase _createExpense;
  final UpdateExpenseUseCase _updateExpense;
  final DeleteExpenseUseCase _deleteExpense;
  final GetSimplifiedDebtsUseCase _getSimplifiedDebts;
  final RecordSettlementUseCase _recordSettlement;

  StreamSubscription<List<ExpenseEntity>>? _expenseSub;
  StreamSubscription<List<SettlementEntity>>? _settlementSub;
  StreamSubscription<List<ExpenseEntity>>? _activityExpenseSub;
  StreamSubscription<List<SettlementEntity>>? _activitySettlementSub;

  void _onLoad(ExpenseLoadRequested event, Emitter<ExpenseState> emit) {
    emit(state.copyWith(status: ExpenseStatus.loading));
    _expenseSub?.cancel();
    _settlementSub?.cancel();
    _expenseSub = _watchGroupExpenses(event.groupId).listen(
      (expenses) => add(_ExpenseListUpdated(expenses)),
    );
    _settlementSub = _watchGroupSettlements(event.groupId).listen(
      (settlements) => add(_SettlementListUpdated(settlements)),
    );
  }

  void _onActivityLoad(
      ActivityLoadRequested event, Emitter<ExpenseState> emit) {
    _activityExpenseSub?.cancel();
    _activitySettlementSub?.cancel();
    if (event.groupIds.isEmpty) {
      emit(state.copyWith(
        activityExpenses: [],
        activitySettlements: [],
      ));
      return;
    }
    _activityExpenseSub = _watchUserActivity.expenses(event.groupIds).listen(
          (expenses) => add(_ActivityExpensesUpdated(expenses)),
        );
    _activitySettlementSub =
        _watchUserActivity.settlements(event.groupIds).listen(
              (settlements) => add(_ActivitySettlementsUpdated(settlements)),
            );
  }

  void _onListUpdated(_ExpenseListUpdated event, Emitter<ExpenseState> emit) {
    emit(state.copyWith(
      status: ExpenseStatus.success,
      expenses: event.expenses,
    ));
  }

  void _onSettlementListUpdated(
      _SettlementListUpdated event, Emitter<ExpenseState> emit) {
    emit(state.copyWith(
      status: ExpenseStatus.success,
      settlements: event.settlements,
    ));
  }

  void _onActivityExpensesUpdated(
      _ActivityExpensesUpdated event, Emitter<ExpenseState> emit) {
    emit(state.copyWith(activityExpenses: event.expenses));
  }

  void _onActivitySettlementsUpdated(
      _ActivitySettlementsUpdated event, Emitter<ExpenseState> emit) {
    emit(state.copyWith(activitySettlements: event.settlements));
  }

  Future<void> _onCreate(
    ExpenseCreateRequested event,
    Emitter<ExpenseState> emit,
  ) async {
    emit(state.copyWith(status: ExpenseStatus.loading));
    final result = await _createExpense(event.params);
    result.fold(
      (f) => emit(state.copyWith(
        status: ExpenseStatus.failure,
        errorMessage: f.message,
      )),
      (_) => emit(state.copyWith(status: ExpenseStatus.success)),
    );
  }

  Future<void> _onUpdate(
    ExpenseUpdateRequested event,
    Emitter<ExpenseState> emit,
  ) async {
    emit(state.copyWith(status: ExpenseStatus.loading));
    final result = await _updateExpense(event.params);
    result.fold(
      (f) => emit(state.copyWith(
        status: ExpenseStatus.failure,
        errorMessage: f.message,
      )),
      (_) => emit(state.copyWith(status: ExpenseStatus.success)),
    );
  }

  Future<void> _onDelete(
    ExpenseDeleteRequested event,
    Emitter<ExpenseState> emit,
  ) async {
    final result = await _deleteExpense(event.expenseId);
    result.fold(
      (f) => emit(state.copyWith(
        status: ExpenseStatus.failure,
        errorMessage: f.message,
      )),
      (_) => emit(state.copyWith(status: ExpenseStatus.success)),
    );
  }

  Future<void> _onDebts(
    ExpenseDebtsRequested event,
    Emitter<ExpenseState> emit,
  ) async {
    final result = await _getSimplifiedDebts(event.groupId);
    result.fold(
      (f) => emit(state.copyWith(
        status: ExpenseStatus.failure,
        errorMessage: f.message,
      )),
      (debts) => emit(state.copyWith(
        status: ExpenseStatus.success,
        simplifiedDebts: debts,
      )),
    );
  }

  Future<void> _onSettle(
    ExpenseSettlementRequested event,
    Emitter<ExpenseState> emit,
  ) async {
    emit(state.copyWith(status: ExpenseStatus.loading));
    final result = await _recordSettlement(event.params);
    await result.fold(
      (f) async => emit(state.copyWith(
        status: ExpenseStatus.failure,
        errorMessage: f.message,
      )),
      (_) async {
        // Re-fetch simplified debts so the settled card disappears immediately
        final debtsResult = await _getSimplifiedDebts(event.params.groupId);
        debtsResult.fold(
          (f) => emit(state.copyWith(status: ExpenseStatus.success)),
          (debts) => emit(state.copyWith(
            status: ExpenseStatus.success,
            simplifiedDebts: debts,
          )),
        );
      },
    );
  }

  @override
  Future<void> close() {
    _expenseSub?.cancel();
    _settlementSub?.cancel();
    _activityExpenseSub?.cancel();
    _activitySettlementSub?.cancel();
    return super.close();
  }
}
