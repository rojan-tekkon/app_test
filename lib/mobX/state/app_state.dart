import 'package:bluetooth_test/mobX/state/auth_error.dart';
import 'package:bluetooth_test/mobX/state/reminder.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mobx/mobx.dart';

part 'app_state.g.dart';

class AppState = _AppState with _$AppState;

abstract class _AppState with Store {
  @observable
  AppScreen currentScreen = AppScreen.login;

  @observable
  bool isLoading = false;

  @observable
  User? currentUser;

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
    final auth = FirebaseAuth.instance;
    final user = auth.currentUser;
    if (user == null) {
      isLoading = false;
      return false;
    }
    final userId = user.uid;
    final collection = await FirebaseFirestore.instance.collection(userId).get();

    try {
      // delete from Firebase
      final firebaseReminder = collection.docs.firstWhere((element) => element.id == reminder.id);
      await firebaseReminder.reference.delete();

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
    final auth = FirebaseAuth.instance;
    final user = auth.currentUser;
    if (user == null) {
      isLoading = false;
      return false;
    }
    final userId = user.uid;

    try {
      final store = FirebaseFirestore.instance;
      final operation = store.batch();
      final collection = await store.collection(userId).get();

      for (final document in collection.docs) {
        operation.delete(document.reference);
      }

      // delete all reminders for this user on Firebase
      await operation.commit();

      // delete the user
      await user.delete();

      // log the user out
      await auth.signOut();

      currentScreen = AppScreen.login;
      return true;
    } on FirebaseAuthException catch (e) {
      authError = AuthError.from(e);
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
    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {}
    isLoading = false;
    currentScreen = AppScreen.login;
    reminders.clear();
  }

  @action
  Future<bool> createReminder(String text) async {
    isLoading = true;
    final userId = currentUser?.uid;
    if (userId == null) {
      isLoading = false;
      return false;
    }
    final creationDate = DateTime.now();
    // final userId = user.uid;
    final firebaseReminder = await FirebaseFirestore.instance.collection(userId).add({
      _DocumentKeys.text: text,
      _DocumentKeys.creationDate: creationDate,
      _DocumentKeys.isDone: false,
    });

    // Create local reminder
    final reminder = Reminder(
      creationDate: creationDate,
      id: firebaseReminder.id,
      text: text,
      isDone: false,
    );

    reminders.add(reminder);
    isLoading = false;
    return true;
  }

  @action
  Future<bool> modify(Reminder reminder, {required bool isDone}) async {
    final userId = currentUser?.uid;
    if (userId == null) {
      isLoading = false;
      return false;
    }

    // update the remote reminder
    final collection = await FirebaseFirestore.instance.collection(userId).get();
    final firebaseReminder = collection.docs.where((element) => element.id == reminder.id).first.reference;

    await firebaseReminder.update({_DocumentKeys.isDone: isDone});

    //update the local reminder
    reminders.firstWhere((element) => element.id == reminder.id).isDone = isDone;

    return true;
  }

  @action
  Future<void> initialize() async {
    isLoading = true;
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      // TODOload reminders from Firebase storage

      await _loadReminders();
      currentScreen = AppScreen.reminders;
    } else {
      currentScreen = AppScreen.login;
    }
  }

  @action
  Future<bool> _loadReminders() async {
    final userId = currentUser?.uid;
    if (userId == null) {
      isLoading = false;
      return false;
    }
    final collection = await FirebaseFirestore.instance.collection(userId).get();

    final reminders = collection.docs
        .map(
          (doc) => Reminder(
            id: doc.id,
            creationDate: DateTime.parse(doc[_DocumentKeys.creationDate] as String),
            text: doc[_DocumentKeys.text] as String,
            isDone: doc[_DocumentKeys.isDone] as bool,
          ),
        )
        .toList();

    this.reminders = ObservableList.of(reminders);
    return true;
  }
}

abstract class _DocumentKeys {
  static const String creationDate = 'creation_date';
  static const String text = 'text';
  static const String isDone = 'is_done';
}

typedef LoginOrRegisterFunction = Future<UserCredential> Function({
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
