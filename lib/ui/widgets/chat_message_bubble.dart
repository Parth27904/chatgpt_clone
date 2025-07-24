// lib/ui/widgets/chat_message_bubble.dart
import 'package:flutter/material.dart';
import 'package:chatgpt_clone/models/message.dart';
import 'package:google_fonts/google_fonts.dart';

class ChatMessageBubble extends StatelessWidget {
  final Message message;

  const ChatMessageBubble({Key? key, required this.message}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isUser = message.sender == MessageSender.user;
    final Color bubbleColor =
    isUser ? Theme.of(context).cardColor : Colors.black;
    final Alignment alignment =
    isUser ? Alignment.centerRight : Alignment.centerLeft;
    final BorderRadius borderRadius = BorderRadius.only(
      topLeft: const Radius.circular(16),
      topRight: const Radius.circular(16),
      bottomLeft: const Radius.circular(16),
      bottomRight: const Radius.circular(16),
    );

    return Align(
      alignment: alignment,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: borderRadius,
        ),
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.imageUrl != null && message.imageUrl!.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(bottom: message.content.isNotEmpty ? 8.0 : 0.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: Image.network(
                    message.imageUrl!,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                              : null,
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white70),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      print('Image.network Error: Failed to load image from URL: ${message.imageUrl}');
                      print('Error details: $error');
                      // stackTrace is usually too verbose for console, use if really needed.
                      return Container(
                        padding: const EdgeInsets.all(8.0),
                        color: Colors.red.withOpacity(0.3), // Clearer error background
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.broken_image, color: Colors.white, size: 40), // More prominent icon
                            const SizedBox(height: 8),
                            Text(
                              'Failed to load image.\nURL: ${message.imageUrl}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.white, fontSize: 12), // Text color
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            if (message.content.isNotEmpty)
              Text(
                message.content,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 16.0,
                  height: 1.4,
                ),
              ),
          ],
        ),
      ),
    );
  }
}