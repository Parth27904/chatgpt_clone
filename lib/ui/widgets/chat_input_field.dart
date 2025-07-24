// lib/ui/widgets/chat_input_field.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:google_fonts/google_fonts.dart';

import 'package:chatgpt_clone/bloc/chat/chat_bloc.dart';

class ChatInputField extends StatefulWidget {
  final TextEditingController textController;
  final VoidCallback onSend;
  final bool isInitialScreen;
  final FocusNode focusNode;

  const ChatInputField({
    Key? key,
    required this.textController,
    required this.onSend,
    this.isInitialScreen = false,
    required this.focusNode,
  }) : super(key: key);

  @override
  State<ChatInputField> createState() => _ChatInputFieldState();
}

class _ChatInputFieldState extends State<ChatInputField> {
  final ImagePicker _picker = ImagePicker();
  bool _isLocalLoading = false;
  late bool _effectiveIsInitialScreen;

  @override
  void initState() {
    super.initState();
    widget.textController.addListener(_onTextChanged);
    _effectiveIsInitialScreen = widget.isInitialScreen;
  }

  @override
  void didUpdateWidget(covariant ChatInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isInitialScreen && !widget.isInitialScreen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _effectiveIsInitialScreen = false;
          });
        }
      });
    } else if (!oldWidget.isInitialScreen && widget.isInitialScreen) {
      if (mounted) {
        setState(() {
          _effectiveIsInitialScreen = true;
        });
      }
    }
  }

  @override
  void dispose() {
    widget.textController.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _onLocalSend() {
    if (!_isLocalLoading) {
      setState(() {
        _isLocalLoading = true;
      });
      widget.onSend();
    }
  }

  void _showImageSourceActionSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF303030),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select Image',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      leading:
                      const Icon(Icons.photo_library, color: Colors.white70),
                      title: Text(
                        'Choose from Gallery',
                        style: GoogleFonts.inter(color: Colors.white),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        _pickImage();
                      },
                    ),
                    ListTile(
                      leading:
                      const Icon(Icons.camera_alt, color: Colors.white70),
                      title: Text(
                        'Take Photo',
                        style: GoogleFonts.inter(color: Colors.white),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        _captureImage();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null && mounted) {
      context.read<ChatBloc>().add(ImagePicked(imageFile: image));
    }
  }

  Future<void> _captureImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image != null && mounted) {
      context.read<ChatBloc>().add(ImagePicked(imageFile: image));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ChatBloc, ChatState>(
      listener: (context, state) {
        if (state.status == ChatStatus.loaded ||
            state.status == ChatStatus.error) {
          if (mounted) {
            setState(() {
              _isLocalLoading = false;
            });
            if (state.status == ChatStatus.loaded &&
                !widget.isInitialScreen &&
                widget.textController.text.isEmpty) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!widget.focusNode.hasFocus) {
                  widget.focusNode.requestFocus();
                }
              });
            }
          }
        }
      },
      child: BlocBuilder<ChatBloc, ChatState>(
        buildWhen: (previous, current) {
          return previous.status != current.status ||
              previous.selectedImage != current.selectedImage ||
              previous.currentConversation != current.currentConversation;
        },
        builder: (context, state) {
          final bool isSending = state.status == ChatStatus.sendingMessage;
          final bool showButtonLoading = _isLocalLoading || isSending;

          final bool hasText = widget.textController.text.isNotEmpty;
          final bool hasImage = state.selectedImage != null;
          final bool canSend = hasText || hasImage;

          final bool showInitialIcons =
              _effectiveIsInitialScreen && !hasText && !hasImage;

          return Container(
            color: Colors.black,
            // **MODIFIED**: Reduced vertical padding for a shorter field
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (state.selectedImage != null)
                  Container(
                    padding: const EdgeInsets.all(8.0),
                    margin: const EdgeInsets.only(bottom: 8.0),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8.0),
                          child: Image.file(
                            File(state.selectedImage!.path),
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 16.0),
                        Expanded(
                          child: Text(
                            state.selectedImage!.name,
                            style: Theme.of(context).textTheme.bodySmall,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white70),
                          onPressed: () {
                            context
                                .read<ChatBloc>()
                                .add(const ClearImageSelection());
                          },
                        ),
                      ],
                    ),
                  ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    CircleAvatar(
                      backgroundColor: const Color(0xFF505050),
                      // **MODIFIED**: Reduced radius to match the send button
                      radius: 22,
                      child: IconButton(
                        icon:Image.asset("assets/photo.png"),
                        onPressed: _showImageSourceActionSheet,
                        splashColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                      ),
                    ),
                    const SizedBox(width: 8.0),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF505050),
                          borderRadius: BorderRadius.circular(25.0),
                        ),
                        padding:
                        const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: TextField(
                                controller: widget.textController,
                                focusNode: widget.focusNode,
                                minLines: 1,
                                autofocus: widget.isInitialScreen,
                                maxLines: 5,
                                keyboardType: TextInputType.multiline,
                                textCapitalization:
                                TextCapitalization.sentences,
                                style: GoogleFonts.inter(
                                    color: Colors.white, fontSize: 16),
                                decoration: InputDecoration(
                                  hintText: 'Ask anything',
                                  hintStyle: GoogleFonts.inter(
                                      color: Colors.white54, fontSize: 16),
                                  border: InputBorder.none,
                                  // **MODIFIED**: Adjusted padding for better text centering
                                  contentPadding: const EdgeInsets.symmetric(
                                      vertical: 10.0, horizontal: 4.0),
                                  suffixIcon: null,
                                ),
                              ),
                            ),
                            if (showInitialIcons) ...[
                              IconButton(
                                icon: const Icon(Icons.mic,
                                    color: Colors.white70, size: 28),
                                onPressed: () {
                                  // TODO: Implement voice input
                                },
                                splashColor: Colors.transparent,
                                highlightColor: Colors.transparent,
                              ),
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: Colors.white,
                                child: IconButton(
                                  padding: EdgeInsets.zero,
                                  icon: const Icon(Icons.graphic_eq,
                                      color: Colors.black, size: 20),
                                  onPressed: () {
                                    // TODO: Implement headphones/audio output
                                  },
                                ),
                              ),
                              const SizedBox(width: 4.0),
                            ] else if (canSend)
                              Padding(
                                padding: const EdgeInsets.all(4.0),
                                child: CircleAvatar(
                                  radius: 18,
                                  backgroundColor: const Color(0xFFFFFFFF),
                                  child: showButtonLoading
                                      ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      valueColor:
                                      AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                    ),
                                  )
                                      : IconButton(
                                    icon: const Icon(Icons.arrow_upward,
                                        color: Colors.black, size: 20),
                                    onPressed:
                                    canSend ? _onLocalSend : null,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}