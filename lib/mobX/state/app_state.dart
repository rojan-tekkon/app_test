import 'package:bluetooth_test/mobX/provider/auth_provider.dart';
import 'package:bluetooth_test/mobX/provider/reminders_provider.dart';
import 'package:bluetooth_test/mobX/state/auth_error.dart';
import 'package:bluetooth_test/mobX/state/reminder.dart';
import 'package:mobx/mobx.dart';

part 'app_state.g.dart';

class AppState = _AppState with _$AppState;

abstract class _AppState with Store {
  final RemindersProvider remindersProvider;
  final AuthProvider authProvider;

  _AppState({required this.remindersProvider, required this.authProvider});

  @observable
  AppScreen currentScreen = AppScreen.login;

  @observable
  bool isLoading = false;

  @observable
  AuthError? authError;

  @observable
  ObservableList<Reminder> reminders = ObservableList<Reminder>();

  @computed
  ObservableList<Reminder> get sortedReminders => ObservableList.of(reminders.sorted());

  @action
  void goto(AppScreen screen) {
    currentScreen = screen;
  }

  @action
  Future<bool> delete(Reminder reminder) async {
    isLoading = true;
    final userId = authProvider.userId;
    if (userId == null) {
      isLoading = false;
      return false;
    }

    try {
      // delete remotely
      await remindersProvider.deleteReminderWithId(reminder.id, userId: userId);

      // delete locally
      reminders.removeWhere((element) => element.id == reminder.id);

      return true;
    } catch (_) {
      return false;
    } finally {
      isLoading = false;
    }
  }

  @action
  Future<bool> deleteAccount() async {
    isLoading = true;
    final userId = authProvider.userId;
    if (userId == null) {
      isLoading = false;
      return false;
    }

    try {
      // delete all documents from firebase
      await remindersProvider.deleteAllDocuments(userId: userId);

      // remove all reminders locally
      reminders.clear();

      // delete the user and signout
      await authProvider.deleteAccountAndSignOut();
      currentScreen = AppScreen.login;
      return true;
    } on AuthError catch (e) {
      authError = e;
      return false;
    } catch (_) {
      return false;
    } finally {
      isLoading = false;
    }
  }

  @action
  Future<void> logOut() async {
    isLoading = true;
    await authProvider.signOut();
    reminders.clear();
    isLoading = false;
    currentScreen = AppScreen.login;
  }

  @action
  Future<bool> createReminder(String text) async {
    isLoading = true;
    final userId = authProvider.userId;
    if (userId == null) {
      isLoading = false;
      return false;
    }
    final creationDate = DateTime.now();

    final cloudReminderId =
        await remindersProvider.createReminder(userId: userId, text: text, creationDate: creationDate);

    // Create local reminder
    final reminder = Reminder(creationDate: creationDate, id: cloudReminderId, text: text, isDone: false);

    reminders.add(reminder);
    isLoading = false;
    return true;
  }

  @action
  Future<bool> modifyReminder({required ReminderId reminderId, required bool isDone}) async {
    final userId = authProvider.userId;
    if (userId == null) {
      isLoading = false;
      return false;
    }

    // update the remote reminder
    await remindersProvider.modify(reminderId: reminderId, isDone: isDone, userId: userId);

    //update the local reminder
    reminders.firstWhere((element) => element.id == reminderId).isDone = isDone;

    return true;
  }

  @action
  Future<void> initialize() async {
    isLoading = true;
    final userId = authProvider.userId;
    if (userId != null) {
      // TODOload reminders from Firebase storage
      await _loadReminders();
      currentScreen = AppScreen.reminders;
    } else {
      currentScreen = AppScreen.login;
    }
    isLoading = false;
  }

  @action
  Future<bool> _loadReminders() async {
    final userId = authProvider.userId;

    if (userId == null) {
      isLoading = false;
      return false;
    }

    final reminders = await remindersProvider.loadReminders(userId: userId);

    this.reminders = ObservableList.of(reminders);
    return true;
  }

  @action
  Future<bool> _registerOrLogin(
      {required LoginOrRegisterFunction fn, required String email, required String password}) async {
    authError = null;
    isLoading = true;
    try {
      final succeded = await fn(email: email, password: password);
      if (succeded) {
        await _loadReminders();
      }
      return succeded;
    } on AuthError catch (e) {
      authError = e;
      return false;
    } finally {
      isLoading = false;
      if (authProvider.userId != null) {
        currentScreen = AppScreen.reminders;
      }
    }
  }

  @action
  Future<bool> register({required String email, required String password}) => _registerOrLogin(
        fn: authProvider.register,
        email: email,
        password: password,
      );

  @action
  Future<bool> login({required String email, required String password}) => _registerOrLogin(
        fn: authProvider.login,
        email: email,
        password: password,
      );
}

typedef LoginOrRegisterFunction = Future<bool> Function({
  required String email,
  required String password,
});

extension ToInt on bool {
  int toInteger() => this ? 1 : 0;
}

extension Sorted on List<Reminder> {
  List<Reminder> sorted() => [...this]..sort((lhs, rhs) {
      final isDone = lhs.isDone.toInteger().compareTo(rhs.isDone.toInteger());

      if (isDone != 0) {
        return isDone;
      }
      return lhs.creationDate.compareTo(rhs.creationDate);
    });
}

enum AppScreen { login, register, reminders }
