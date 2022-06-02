import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';

const apiUrl = "http://127.0.0.1:5500/lib/api/people.json";

@immutable
class Person {
  final String name;
  final int age;
  const Person({required this.name, required this.age});

  Person.fromJson(Map<String, dynamic> json)
      : name = json['name'] as String,
        age = json['age'] as int;

  @override
  String toString() => 'Person(name: $name, age: $age years old)';
}

Future<Iterable<Person>> getPersons() => HttpClient()
    .getUrl(Uri.parse(apiUrl))
    .then((req) => req.close())
    .then((resp) => resp.transform(utf8.decoder).join())
    .then((str) => json.decode(str) as List<dynamic>)
    .then((list) => list.map((e) => Person.fromJson(e)));

@immutable
abstract class Action {
  const Action();
}

@immutable
class LoadPeopleAction extends Action {
  const LoadPeopleAction();
}

@immutable
class SuccessfullyFetchedPeopleAction extends Action {
  final Iterable<Person> persons;
  const SuccessfullyFetchedPeopleAction({required this.persons});
}

@immutable
class FailedToFetchedPeopleAction extends Action {
  final Object error;
  const FailedToFetchedPeopleAction({required this.error});
}

@immutable
class State {
  final bool isLoading;
  final Iterable<Person>? fetchedPersons;
  final Object? error;

  const State({
    required this.isLoading,
    required this.fetchedPersons,
    required this.error,
  });

  const State.empty()
      : isLoading = false,
        fetchedPersons = null,
        error = null;
}

State reducer(State oldState, action) {
  if (action is LoadPeopleAction) {
    return const State(isLoading: true, fetchedPersons: null, error: null);
  } else if (action is SuccessfullyFetchedPeopleAction) {
    return State(isLoading: false, fetchedPersons: action.persons, error: null);
  } else if (action is FailedToFetchedPeopleAction) {
    return State(isLoading: false, fetchedPersons: oldState.fetchedPersons, error: action.error);
  }
  return oldState;
}

void loadPeopleMiddleWare(Store<State> store, action, NextDispatcher next) {
  if (action is LoadPeopleAction) {
    getPersons().then((persons) {
      store.dispatch(SuccessfullyFetchedPeopleAction(persons: persons));
    }).catchError((error) {
      store.dispatch(FailedToFetchedPeopleAction(error: error));
    });
  }
  next(action);
}

class LoadDataScreen extends StatelessWidget {
  const LoadDataScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final store = Store(
      reducer,
      initialState: const State.empty(),
      middleware: [loadPeopleMiddleWare],
    );
    return Scaffold(
      appBar: AppBar(
        title: const Text('Redux async example'),
      ),
      body: StoreProvider(
        store: store,
        child: Padding(
          padding: const EdgeInsets.all(25),
          child: Column(
            children: [
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    store.dispatch(const LoadPeopleAction());
                  },
                  child: const Text("Load Persons"),
                ),
              ),
              StoreConnector<State, bool>(
                converter: (store) => store.state.isLoading,
                builder: (context, isLoading) {
                  if (isLoading) {
                    return const CircularProgressIndicator();
                  }
                  return const SizedBox();
                },
              ),
              StoreConnector<State, Iterable<Person>?>(
                converter: (store) => store.state.fetchedPersons,
                builder: (context, people) {
                  if (people == null) {
                    return const SizedBox();
                  } else {
                    return Expanded(
                      child: ListView.builder(
                        itemCount: people.length,
                        itemBuilder: (context, index) {
                          final person = people.elementAt(index);
                          return ListTile(
                            title: Text(person.name),
                            subtitle: Text("${person.age} years old"),
                          );
                        },
                      ),
                    );
                  }
                },
              )
            ],
          ),
        ),
      ),
    );
  }
}
