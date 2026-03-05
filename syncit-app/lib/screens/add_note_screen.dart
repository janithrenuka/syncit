import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:syncit/models/note.dart';
import 'package:syncit/services/note_service.dart';

class AddNoteScreen extends StatefulWidget {
  final Note? existingNote;
  final int? index;

  const AddNoteScreen({super.key, this.existingNote, this.index});

  @override
  State<AddNoteScreen> createState() => _AddNoteScreenState();
}

class _AddNoteScreenState extends State<AddNoteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _topicController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _isPreviewMode = false;
  List<String> _attachments = [];

  @override
  void initState() {
    super.initState();
    if (widget.existingNote != null) {
      _topicController.text = widget.existingNote!.topic;
      _descriptionController.text = widget.existingNote!.description;
      _attachments = List<String>.from(widget.existingNote!.attachmentList);
    }
  }

  @override
  void dispose() {
    _topicController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      final note = Note(
        topic: _topicController.text.trim(),
        description: _descriptionController.text.trim(),
        attachmentList: _attachments,
      );

      final noteService = NoteService();
      if (widget.index != null) {
        await noteService.updateNote(widget.index!, note);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Note Updated Successfully!')),
          );
        }
      } else {
        await noteService.addNote(note);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Note Added Successfully!')),
          );
        }
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    }
  }

  Future<void> _addAttachment() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['png', 'jpg', 'jpeg'],
        allowMultiple: true,
      );

      if (result != null) {
        final appDir = await getApplicationDocumentsDirectory();
        final syncitAttDir = Directory('${appDir.path}/syncit_attachments');
        if (!await syncitAttDir.exists()) {
          await syncitAttDir.create(recursive: true);
        }

        List<String> newPaths = [];
        for (var file in result.files) {
          if (file.path != null) {
            final File tempFile = File(file.path!);
            // Create a unique filename to avoid overwrites
            final String fileName =
                '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
            final String finalPath = '${syncitAttDir.path}/$fileName';

            await tempFile.copy(finalPath);
            newPaths.add(finalPath);
          }
        }

        setState(() {
          _attachments.addAll(newPaths);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error adding attachment: $e')));
      }
    }
  }

  void _removeAttachment(int index) async {
    try {
      final path = _attachments[index];
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
      setState(() {
        _attachments.removeAt(index);
      });
    } catch (e) {
      debugPrint('Error deleting attachment: $e');
    }
  }

  Widget _buildAttachmentsList() {
    if (_attachments.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),
        const Text(
          'Attachments',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children: _attachments.asMap().entries.map((entry) {
            final int index = entry.key;
            final String path = entry.value;
            final String fileName = path.split('/').last;
            final bool isImage =
                fileName.toLowerCase().endsWith('.jpg') ||
                fileName.toLowerCase().endsWith('.jpeg') ||
                fileName.toLowerCase().endsWith('.png');

            return Chip(
              avatar: Icon(
                isImage ? Icons.image : Icons.insert_drive_file,
                color: Colors.purple,
                size: 20,
              ),
              label: Container(
                constraints: const BoxConstraints(maxWidth: 150),
                child: Text(fileName, overflow: TextOverflow.ellipsis),
              ),
              deleteIcon: const Icon(Icons.close, size: 18),
              onDeleted: () => _removeAttachment(index),
              backgroundColor: Colors.purple.withAlpha(20),
            );
          }).toList(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Colors.purple;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.existingNote != null ? 'Edit Note' : 'Add Note',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.attach_file),
            tooltip: 'Add Attachment',
            onPressed: _addAttachment,
          ),
          IconButton(
            icon: const Icon(Icons.check),
            tooltip: widget.existingNote != null ? 'Update Note' : 'Save Note',
            onPressed: _submit,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Topic Field
                    TextFormField(
                      controller: _topicController,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Note Topic',
                        border: InputBorder.none,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a Topic';
                        }
                        return null;
                      },
                    ),
                    const Divider(height: 32, thickness: 1),

                    // Action Bar (Edit / Preview Toggle & Formats)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Edit & Preview Toggle
                        SegmentedButton<bool>(
                          segments: const [
                            ButtonSegment<bool>(
                              value: false,
                              label: Text('Edit'),
                              icon: Icon(Icons.edit),
                            ),
                            ButtonSegment<bool>(
                              value: true,
                              label: Text('Preview'),
                              icon: Icon(Icons.visibility),
                            ),
                          ],
                          selected: {_isPreviewMode},
                          onSelectionChanged: (Set<bool> newSelection) {
                            setState(() {
                              _isPreviewMode = newSelection.first;
                            });
                          },
                          style: SegmentedButton.styleFrom(
                            selectedBackgroundColor: primaryColor.withAlpha(50),
                            selectedForegroundColor: primaryColor,
                          ),
                        ),

                        // Formatting Actions (Only active when editing)
                        if (!_isPreviewMode)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildFormatActionIcon(
                                Icons.format_list_bulleted,
                                'Bullets',
                                primaryColor,
                                () => _insertTextAtCursor('\n- '),
                              ),
                              _buildFormatActionIcon(
                                Icons.format_list_numbered,
                                'Numbering',
                                primaryColor,
                                () {
                                  final text = _descriptionController.text;
                                  final selection =
                                      _descriptionController.selection;
                                  int cursorPosition = selection.isValid
                                      ? selection.start
                                      : text.length;
                                  if (cursorPosition < 0) {
                                    cursorPosition = text.length;
                                  }

                                  // Get text before cursor
                                  final textBeforeCursor = text.substring(
                                    0,
                                    cursorPosition,
                                  );

                                  // Split into lines
                                  final lines = textBeforeCursor.split('\n');

                                  int nextNumber = 1;

                                  // Find the most recent numbered list item looking backwards
                                  for (int i = lines.length - 1; i >= 0; i--) {
                                    final line = lines[i].trim();
                                    final match = RegExp(
                                      r'^(\d+)\.',
                                    ).firstMatch(line);
                                    if (match != null) {
                                      nextNumber =
                                          int.parse(match.group(1)!) + 1;
                                      break;
                                    }
                                    // If we hit a non-empty line that isn't a numbered list, we start a new list
                                    if (line.isNotEmpty) {
                                      break;
                                    }
                                  }

                                  _insertTextAtCursor('\n$nextNumber. ');
                                },
                              ),
                              _buildFormatActionIcon(
                                Icons.format_italic,
                                'Italics',
                                primaryColor,
                                () {
                                  final text = _descriptionController.text;
                                  final selection =
                                      _descriptionController.selection;
                                  if (selection.isValid &&
                                      selection.start != selection.end) {
                                    final selectedText = text.substring(
                                      selection.start,
                                      selection.end,
                                    );
                                    _descriptionController.text = text
                                        .replaceRange(
                                          selection.start,
                                          selection.end,
                                          '*$selectedText*',
                                        );
                                    _descriptionController.selection =
                                        TextSelection.collapsed(
                                          offset:
                                              selection.start +
                                              selectedText.length +
                                              2,
                                        );
                                  } else {
                                    _insertTextAtCursor('*italic*');
                                  }
                                },
                              ),
                            ],
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Editor & Preview Body
                    Container(
                      constraints: BoxConstraints(
                        minHeight: MediaQuery.of(context).size.height * 0.4,
                      ),
                      decoration: BoxDecoration(
                        color: _isPreviewMode
                            ? Colors.grey.withAlpha(20)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: _isPreviewMode
                          ? const EdgeInsets.all(16)
                          : EdgeInsets.zero,
                      child: _isPreviewMode
                          ? _descriptionController.text.trim().isEmpty
                                ? const Text(
                                    'Nothing to preview yet...',
                                    style: TextStyle(color: Colors.grey),
                                  )
                                : MarkdownBody(
                                    data: _descriptionController.text,
                                    selectable: true,
                                  )
                          : TextFormField(
                              controller: _descriptionController,
                              maxLines: null,
                              keyboardType: TextInputType.multiline,
                              decoration: const InputDecoration(
                                hintText:
                                    'Start writing your note here using Markdown formatting...',
                                border: InputBorder.none,
                              ),
                            ),
                    ),

                    // Attachments Rendering
                    _buildAttachmentsList(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _insertTextAtCursor(String textToInsert) {
    final text = _descriptionController.text;
    final selection = _descriptionController.selection;

    int cursorPosition = selection.isValid ? selection.start : text.length;
    if (cursorPosition < 0) {
      cursorPosition = text.length;
    }

    final newText = text.replaceRange(
      cursorPosition,
      cursorPosition,
      textToInsert,
    );

    _descriptionController.text = newText;
    _descriptionController.selection = TextSelection.collapsed(
      offset: cursorPosition + textToInsert.length,
    );
  }

  Widget _buildFormatActionIcon(
    IconData icon,
    String tooltip,
    Color color,
    VoidCallback onPressed,
  ) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(8),
          margin: const EdgeInsets.only(left: 4),
          decoration: BoxDecoration(
            color: color.withAlpha(20),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
      ),
    );
  }
}
