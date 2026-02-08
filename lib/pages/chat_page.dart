import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:recipeappflutter/models/chat_message.dart';
import 'package:recipeappflutter/services/chat_service.dart';
import 'package:recipeappflutter/pages/detail_page.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final ChatService _chatService = ChatService();
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  final Map<String, Recipe> _recipeCache = {}; // Store recipes by message ID
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _messages.add(
      ChatMessage(
        id: '0',
        role: 'assistant',
        content:
            'Hi! I\'m SavorAI Chef 👨‍🍳\n\nTell me what ingredients you have, and I\'ll create a delicious recipe for you!\n\nExample: "chicken, tomato, garlic, basil"',
        timestamp: DateTime.now(),
      ),
    );
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage() async {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;

    _inputController.clear();

    setState(() {
      _messages.add(
        ChatMessage(
          id: DateTime.now().toString(),
          role: 'user',
          content: text,
          timestamp: DateTime.now(),
        ),
      );
      _isLoading = true;
    });

    _scrollToBottom();

    try {
      final recipe = await _chatService.generateRecipe(text);

      // Add recipe message to chat
      final recipeMessageId = DateTime.now().toString();
      _recipeCache[recipeMessageId] = recipe;

      setState(() {
        _messages.add(
          ChatMessage(
            id: recipeMessageId,
            role: 'recipe',
            content: '', // We'll use recipe data instead
            timestamp: DateTime.now(),
          ),
        );
        _isLoading =
            false;
      });

      // Send recipe to admin approval in background
      _sendRecipeToAdmin(recipe).catchError((e) {
        print('Background save error: $e');
      });

      _scrollToBottom();
    } catch (e) {
      print('Error in _sendMessage: $e');
      setState(() {
        _messages.add(
          ChatMessage(
            id: DateTime.now().toString(),
            role: 'assistant',
            content:
                ' Sorry, I couldn\'t generate a recipe.\n\nError: $e\n\nMake sure the backend is running.',
            timestamp: DateTime.now(),
          ),
        );
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  Future<void> _sendRecipeToAdmin(Recipe recipe) async {
    try {
      print('Starting to save recipe to Firestore...');
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        print('ERROR: No user logged in!');
        return;
      }

      print('User: ${user.uid}, Email: ${user.email}');

      final docRef =
          await FirebaseFirestore.instance.collection('recipes').add({
        'name': recipe.name,
        'description': recipe.description,
        'ingredients': recipe.ingredients,
        'instructions': recipe.instructions,
        'cookingTime': recipe.cookingTime,
        'servings': recipe.servings,
        'category': recipe.category,
        'tips': recipe.tips,
        'userId': user.uid,
        'userEmail': user.email,
        'createdAt': FieldValue.serverTimestamp(),
        'approved': true, // auto-approve chatbot-created recipes
        'generated': true,
        'imageUrl': 'images/Noimage.png',
        'averageRating': 0.0,
        'ratings': {},
      });

      print(' Recipe saved successfully! Document ID: ${docRef.id}');
    } catch (e) {
      print(' Error sending recipe: $e');
      print('Error type: ${e.runtimeType}');
    }
  }

  void _showRecipePreview(Recipe recipe) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.restaurant,
                          color: Color(0xFFFF6B35), size: 28),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          recipe.name,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    recipe.description,
                    style: TextStyle(color: Colors.grey[700], fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildInfoChip(
                          Icons.schedule, '${recipe.cookingTime} mins'),
                      _buildInfoChip(
                          Icons.people, '${recipe.servings} servings'),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF6B35).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          recipe.category,
                          style: const TextStyle(
                            color: Color(0xFFFF6B35),
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DetailPage(
                              recipeName: recipe.name,
                              recipeData: {
                                'name': recipe.name,
                                'description': recipe.description,
                                'ingredients': recipe.ingredients,
                                'instructions': recipe.instructions,
                                'cookingTime': recipe.cookingTime,
                                'servings': recipe.servings,
                                'category': recipe.category,
                                'imageUrl': 'images/Noimage.png',
                                'averageRating': 0.0,
                              },
                              recipeId:
                                  'ai_${DateTime.now().millisecondsSinceEpoch}',
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF6B35),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.visibility, color: Colors.white),
                      label: const Text(
                        'View Full Recipe',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: Color(0xFFFF6B35)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child:
                          const Text('Close', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: 13, color: Colors.grey[700])),
      ],
    );
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '🤖 SavorAI Chef',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFFFF6B35),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFF5E1), Color(0xFFFFE8D6)],
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length + (_isLoading ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _messages.length && _isLoading) {
                    return _buildLoadingIndicator();
                  }

                  final msg = _messages[index];
                  final isUser = msg.role == 'user';

                  // Handle recipe messages
                  if (msg.role == 'recipe') {
                    final recipe = _recipeCache[msg.id];
                    if (recipe != null) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildBotAvatar(),
                            const SizedBox(width: 8),
                            Flexible(child: _buildRecipeCard(recipe, msg.id)),
                          ],
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      mainAxisAlignment: isUser
                          ? MainAxisAlignment.end
                          : MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!isUser) _buildBotAvatar(),
                        if (!isUser) const SizedBox(width: 8),
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: isUser
                                  ? const Color(0xFFFF6B35)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              msg.content,
                              style: TextStyle(
                                color: isUser ? Colors.white : Colors.black87,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                        if (isUser) const SizedBox(width: 8),
                        if (isUser) _buildUserAvatar(),
                      ],
                    ),
                  );
                },
              ),
            ),
            _buildInputBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildRecipeCard(Recipe recipe, String messageId) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.restaurant, color: Color(0xFFFF6B35), size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  recipe.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            recipe.description,
            style: TextStyle(color: Colors.grey[700], fontSize: 13),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSmallInfoChip(Icons.schedule, '${recipe.cookingTime} mins'),
              _buildSmallInfoChip(Icons.people, '${recipe.servings} servings'),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B35).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  recipe.category,
                  style: const TextStyle(
                    color: Color(0xFFFF6B35),
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DetailPage(
                      recipeName: recipe.name,
                      recipeData: {
                        'name': recipe.name,
                        'description': recipe.description,
                        'ingredients': recipe.ingredients,
                        'instructions': recipe.instructions,
                        'cookingTime': recipe.cookingTime,
                        'servings': recipe.servings,
                        'category': recipe.category,
                        'imageUrl': 'images/Noimage.png',
                        'averageRating': 0.0,
                      },
                      recipeId: 'ai_${DateTime.now().millisecondsSinceEpoch}',
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B35),
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(Icons.visibility, color: Colors.white, size: 18),
              label: const Text(
                'View Full Recipe',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallInfoChip(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey[600]),
        const SizedBox(width: 3),
        Text(text, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
      ],
    );
  }

  Widget _buildLoadingIndicator() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          _buildBotAvatar(),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: const [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Color(0xFFFF6B35)),
                    ),
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Cooking up a recipe...',
                    style: TextStyle(
                        color: Colors.grey, fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBotAvatar() {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [Color(0xFF6C63FF), Color(0xFF00C2FF)],
        ),
      ),
      child:
          const Icon(Icons.smart_toy_outlined, color: Colors.white, size: 20),
    );
  }

  Widget _buildUserAvatar() {
    return const CircleAvatar(
      radius: 18,
      backgroundColor: Color(0xFFFF6B35),
      child: Icon(Icons.person, color: Colors.white, size: 20),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _inputController,
              decoration: InputDecoration(
                hintText: 'Enter ingredients (e.g., chicken, tomato)...',
                hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide:
                      const BorderSide(color: Color(0xFFFF6B35), width: 2),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              enabled: !_isLoading,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            decoration: BoxDecoration(
              gradient: _isLoading
                  ? null
                  : const LinearGradient(
                      colors: [Color(0xFFFF6B35), Color(0xFFFFA500)]),
              color: _isLoading ? Colors.grey : null,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: _isLoading ? null : _sendMessage,
              icon: const Icon(Icons.send_rounded, color: Colors.white),
              iconSize: 24,
            ),
          ),
        ],
      ),
    );
  }
}
