import 'dart:convert';

import 'package:appflowy/plugins/document/presentation/editor_plugins/copy_and_paste/clipboard_service.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';

/// Copy.
///
/// - support
///   - desktop
///   - web
///   - mobile
///
final CommandShortcutEvent customCopyCommand = CommandShortcutEvent(
  key: 'copy the selected content',
  getDescription: () => AppFlowyEditorL10n.current.cmdCopySelection,
  command: 'ctrl+c',
  macOSCommand: 'cmd+c',
  handler: _copyCommandHandler,
);

CommandShortcutEventHandler _copyCommandHandler = (editorState) {
  final selection = editorState.selection?.normalized;
  if (selection == null) {
    return KeyEventResult.ignored;
  }

  String? text;
  String? html;
  String? inAppJson;

  if (selection.isCollapsed) {
    // if the selection is collapsed, we will copy the text of the current line.
    final node = editorState.getNodeAtPath(selection.end.path);
    if (node == null) {
      return KeyEventResult.ignored;
    }

    // plain text.
    text = node.delta?.toPlainText();

    // in app json
    final document = Document.blank()..insert([0], [node.copyWith()]);
    inAppJson = jsonEncode(document.toJson());

    // html
    html = documentToHTML(document);
  } else {
    // plain text.
    text = editorState.getTextInSelection(selection).join('\n');

    final nodes = editorState.getSelectedNodes(selection: selection);
    final document = Document.blank()..insert([0], nodes);

    // in app json
    inAppJson = jsonEncode(document.toJson());

    // html
    html = documentToHTML(document);
  }

  () async {
    await getIt<ClipboardService>().setData(
      ClipboardServiceData(
        plainText: text,
        html: html,
        inAppJson: inAppJson,
      ),
    );
  }();

  return KeyEventResult.handled;
};
