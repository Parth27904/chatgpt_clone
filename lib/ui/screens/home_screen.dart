// lib/ui/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:chatgpt_clone/bloc/chat/chat_bloc.dart';
import 'package:chatgpt_clone/bloc/model_selection/model_selection_bloc.dart';
import 'package:chatgpt_clone/ui/widgets/chat_input_field.dart';
import 'package:chatgpt_clone/ui/widgets/chat_message_bubble.dart';
import 'package:chatgpt_clone/ui/screens/chat_history_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _chatInputFocusNode = FocusNode(); // <--- Managed at HomeScreen level

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage() {
    final chatBloc = context.read<ChatBloc>();
    final String content = _textController.text.trim();
    final XFile? imageFileToSend = chatBloc.state.selectedImage;

    if (content.isNotEmpty || imageFileToSend != null) {
      chatBloc.add(SendMessage(content: content, imageFile: imageFileToSend));
      _textController.clear();
      _chatInputFocusNode.unfocus(); // Unfocus after sending
      _scrollToBottom();
    }
  }

  @override
  void initState() {
    super.initState();
    context.read<ChatBloc>().stream.listen((state) {
      if (state.status == ChatStatus.loaded || state.status == ChatStatus.sendingMessage) {
        _scrollToBottom();
      }
    });

    // Initial request for focus when HomeScreen is first built (for new chat)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _chatInputFocusNode.requestFocus();
      print('HomeScreen: Initial focus requested in initState.');
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _chatInputFocusNode.dispose(); // <--- Dispose the FocusNode
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        // **MODIFIED APPBAR**
        appBar: AppBar(
          surfaceTintColor: Colors.transparent,
          toolbarHeight: kToolbarHeight,
          automaticallyImplyLeading: false, // No default back button
          // The 'leading' widget is for the far left of the AppBar.
          leading: Builder(
            builder: (BuildContext context) {
              return IconButton(
                icon: Image.asset("assets/img.png"),
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
              );
            },
          ),
          // The 'title' widget is automatically centered.
          title: Text(
            'ChatGPT',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          // 'actions' are a list of widgets for the far right.
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: BlocBuilder<ModelSelectionBloc, ModelSelectionState>(
                builder: (context, modelState) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1B1B1B),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.0),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: modelState.selectedModel,
                        dropdownColor: const Color(0xFF282828),
                        style: GoogleFonts.inter(color: Colors.white, fontSize: 15),
                        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white70),
                        isDense: true,
                        onChanged: (String? newModel) {
                          if (newModel != null) {
                            context.read<ModelSelectionBloc>().add(SelectModel(newModel));
                          }
                        },
                        selectedItemBuilder: (BuildContext context) {
                          return modelState.availableModels.map<Widget>((String item) {
                            return Center(
                              child: Text(
                                item,
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            );
                          }).toList();
                        },
                        items: modelState.availableModels
                            .map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Row(
                              children: [
                                Icon(Icons.smart_toy_outlined, color: Colors.white.withOpacity(0.7), size: 18),
                                const SizedBox(width: 10),
                                Text(value),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        drawer: Drawer(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          child: ChatHistoryScreen(),
        ),
        body: BlocConsumer<ChatBloc, ChatState>(
          listener: (context, state) {
            if (state.status == ChatStatus.error) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.error ?? 'An unknown error occurred'),
                  backgroundColor: Colors.red,
                ),
              );
            }
            if ((state.status == ChatStatus.loaded || state.status == ChatStatus.error) &&
                (state.currentConversation == null || state.currentConversation!.messages.isEmpty)) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (_textController.text.isEmpty) {
                  _chatInputFocusNode.requestFocus();
                  print('HomeScreen: Requesting focus from BlocListener after operation completes.');
                }
              });
            }
          },
          builder: (context, state) {
            final bool isChatEmpty = state.currentConversation == null || state.currentConversation!.messages.isEmpty;
            final bool showOverallLoadingOverlay = state.isImageUploadInProgress;

            String loadingText = 'Uploading image...';

            return Column(
              children: [
                const SizedBox(height: 10),
                Expanded(
                  child: Stack(
                    children: [
                      isChatEmpty
                          ? _buildInitialChatScreen(context)
                          : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.only(bottom: 16.0),
                        itemCount: state.currentConversation!.messages.length,
                        itemBuilder: (context, index) {
                          final message = state.currentConversation!.messages[index];
                          return ChatMessageBubble(message: message);
                        },
                      ),
                      if (showOverallLoadingOverlay)
                        Positioned.fill(
                          child: Container(
                            color: Colors.black.withOpacity(0.5),
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    loadingText,
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                ChatInputField(
                  textController: _textController,
                  onSend: _sendMessage,
                  isInitialScreen: isChatEmpty,
                  focusNode: _chatInputFocusNode,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildInitialChatScreen(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'What can I help with?',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 23,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildSuggestionButton(context, 'Get advice', Icons.school_outlined, Colors.cyan),
              _buildSuggestionButton(context, 'Make a plan', Icons.lightbulb_outline, Colors.yellow),
            ],
          ),
          const SizedBox(height: 10),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildSuggestionButton(context, 'Code', Icons.code,Colors.purple),
              _buildSuggestionButton(context, 'Analyze images', Icons.visibility_outlined,Colors.purpleAccent),
              _buildSuggestionButton(context, 'More', Icons.more_horiz,Colors.white),
            ],
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildSuggestionButton(BuildContext context, String text, IconData icon, Color iconColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: OutlinedButton.icon(
        onPressed: () {
          _textController.text = text;
          _sendMessage();
        },
        style: OutlinedButton.styleFrom(
          backgroundColor: const Color(0xFF000000),
          foregroundColor: Colors.white,
          side: const BorderSide(color: Color(0xFF4C4C4C), width: 1.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30.0),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        icon: Icon(icon, size: 17, color: iconColor),
        label: Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF858585),
          ),
        ),
      ),
    );
  }
}