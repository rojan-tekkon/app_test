import 'package:bluetooth_test/dialogs/delete_reminder_dialog.dart';
import 'package:bluetooth_test/dialogs/show_textfield_dialog.dart';
import 'package:bluetooth_test/mobX/state/app_state.dart';
import 'package:bluetooth_test/mobX/views/main_popup_menu_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:provider/provider.dart';

class RemindersView extends StatelessWidget {
  const RemindersView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Reminders"),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              final reminderText = await showTextFieldDialog(
                context: context,
                title: "What do you want me to remind you about?",
                hintText: "Enter your reminder here...",
                optionsBuilder: () => {
                  TextFieldDialogButtonType.cancel: 'Cancel',
                  TextFieldDialogButtonType.confirm: 'Save',
                },
              );
              if (reminderText == null) {
                return;
              }
              context.read<AppState>().createReminder(reminderText);
            },
          ),
          const MainPopupMenuButton(),
        ],
      ),
      body: const ReminderListView(),
    );
  }
}

class ReminderListView extends StatelessWidget {
  const ReminderListView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    return Observer(
      builder: (context) {
        return ListView.builder(
          itemCount: appState.sortedReminders.length,
          itemBuilder: (context, index) {
            final reminder = appState.sortedReminders[index];

            return Observer(builder: (context) {
              return CheckboxListTile(
                controlAffinity: ListTileControlAffinity.leading,
                value: reminder.isDone,
                onChanged: (isDone) {
                  context.read<AppState>().modifyReminder(reminderId: reminder.id, isDone: isDone ?? false);
                  reminder.isDone = isDone ?? false;
                },
                title: Row(
                  children: [
                    Expanded(child: Text(reminder.text)),
                    IconButton(
                      onPressed: () async {
                        final shouldDeleteReminder = await showDeleteReminderDialog(context);
                        if (shouldDeleteReminder) {
                          context.read<AppState>().delete(reminder);
                        }
                      },
                      icon: const Icon(Icons.delete),
                    )
                  ],
                ),
              );
            });
          },
        );
      },
    );
  }
}
