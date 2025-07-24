import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:chatgpt_clone/bloc/chat_history/chat_history_bloc.dart';
import 'package:chatgpt_clone/bloc/chat/chat_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/conversation.dart';

class ChatHistoryScreen extends StatefulWidget {
  const ChatHistoryScreen({Key? key}) : super(key: key);

  @override
  State<ChatHistoryScreen> createState() => _ChatHistoryScreenState();
}

class _ChatHistoryScreenState extends State<ChatHistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black, // Background color matching the screenshot
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 50.0, 16.0, 8.0),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF202123),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: GoogleFonts.inter(color: Colors.white, fontSize: 16),
                      decoration: InputDecoration(
                        hintText: 'Search',
                        hintStyle: GoogleFonts.inter(color: Colors.white54, fontSize: 16),
                        border: InputBorder.none,
                        prefixIcon: const Icon(Icons.search, color: Colors.white70, size: 24),
                        contentPadding: const EdgeInsets.symmetric(vertical: 8.0),
                      ),
                      onChanged: (value) => _onSearchChanged(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // New Chat Option
          _buildDrawerMenuItem(
            context,
            'New chat',
            Icons.add_outlined,
            onTap: () {
              context.read<ChatBloc>().add(const NewChatStarted());
              Navigator.of(context).pop(); // Close drawer
            },
          ),
          const Divider(color: Colors.white12, height: 1, thickness: 1),

          Expanded(
            child: BlocBuilder<ChatHistoryBloc, ChatHistoryState>(
              builder: (context, state) {
                if (state.status == ChatHistoryStatus.loading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state.status == ChatHistoryStatus.error) {
                  return Center(child: Text('Error: ${state.error}'));
                } else if (state.conversations.isEmpty && _searchQuery.isEmpty) {
                  return Center(
                    child: Text(
                      'No past conversations.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  );
                }

                final filteredConversations = _searchQuery.isEmpty
                    ? state.conversations
                    : state.conversations.where((conv) {
                  final title = conv.messages.isNotEmpty
                      ? conv.messages.first.content.split('\n').first
                      : 'New Chat (${DateFormat.MMMEd().format(conv.createdAt)})';
                  return title.toLowerCase().contains(_searchQuery.toLowerCase());
                }).toList();

                if (filteredConversations.isEmpty && _searchQuery.isNotEmpty) {
                  return Center(
                    child: Text(
                      'No matching conversations found.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  );
                }

                final sortedConversations = List<Conversation>.from(filteredConversations);
                sortedConversations.sort((a, b) => b.createdAt.compareTo(a.createdAt));

                return ListView.builder(
                  itemCount: sortedConversations.length,
                  itemBuilder: (context, index) {
                    final conversation = sortedConversations[index];
                    final String title = conversation.messages.isNotEmpty
                        ? conversation.messages.first.content.split('\n').first
                        : 'New Chat (${DateFormat.MMMEd().format(conversation.createdAt)})';

                    return Dismissible(
                      key: Key(conversation.id),
                      direction: DismissDirection.endToStart,
                      onDismissed: (direction) {
                        context
                            .read<ChatHistoryBloc>()
                            .add(DeleteConversationFromHistory(conversation.id));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Chat "${title}" dismissed'),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      // --- REVERTED CHAT HISTORY CARD LOOK HERE ---
                      child: Card(
                        margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                        elevation: 2, // Original elevation
                        color: Theme.of(context).cardColor, // Original card color
                        child: ListTile(
                          title: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleSmall, // Original style
                          ),
                          subtitle: Text(
                            DateFormat.yMMMd().add_jm().format(conversation.createdAt),
                            style: Theme.of(context).textTheme.bodySmall, // Original style
                          ),
                          onTap: () {
                            context.read<ChatBloc>().add(ChatStarted(conversationId: conversation.id));
                            Navigator.of(context).pop(); // Close the drawer
                          },
                          trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white54), // Original trailing icon
                          // You might want to adjust ListTile's contentPadding if needed for exact spacing
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        ),
                      ),
                      // --- END REVERTED SECTION ---
                    );
                  },
                );
              },
            ),
          ),
          // User Profile Section at the Bottom
          const Divider(color: Colors.white12, height: 0, thickness: 1),
          _buildUserProfileSection(context),
        ],
      ),
    );
  }

  // Helper method for common drawer menu items
  Widget _buildDrawerMenuItem(BuildContext context, String title, IconData icon, {VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8.0),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Row(
              children: [
                Icon(icon, color: Colors.white70, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper method for the User Profile Section
  Widget _buildUserProfileSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: InkWell(
        onTap: () {
          print('User profile clicked');
        },
        borderRadius: BorderRadius.circular(8.0),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            children: [
              const CircleAvatar(
                radius: 18,
                backgroundImage: NetworkImage(
                  'https://www.w3schools.com/howto/img_avatar.png',
                ),
                backgroundColor: Colors.white24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'User',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}