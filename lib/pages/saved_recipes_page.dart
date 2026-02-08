import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:recipeappflutter/services/auth_service.dart';
import 'package:recipeappflutter/services/database_service.dart';
import 'package:recipeappflutter/pages/detail_page.dart';

class SavedRecipesPage extends StatefulWidget {
  const SavedRecipesPage({super.key});

  @override
  State<SavedRecipesPage> createState() => _SavedRecipesPageState();
}

class _SavedRecipesPageState extends State<SavedRecipesPage> {
  final DatabaseService _databaseService = DatabaseService();
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    final userId = _authService.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Saved Recipes',
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
        child: userId == null
            ? const Center(
                child: Text('Please log in to view saved recipes'),
              )
            : StreamBuilder<DocumentSnapshot>(
                stream: _databaseService.getUserFavorites(userId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Error: ${snapshot.error}'),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data?.data() == null) {
                    return const Center(
                      child: Text(
                        'No saved recipes yet',
                        style: TextStyle(
                          fontSize: 18,
                          color: Color(0xFF999999),
                        ),
                      ),
                    );
                  }

                  final userData =
                      snapshot.data!.data() as Map<String, dynamic>;
                  final favorites =
                      List<String>.from(userData['favorites'] ?? []);

                  if (favorites.isEmpty) {
                    return const Center(
                      child: Text(
                        'No saved recipes yet',
                        style: TextStyle(
                          fontSize: 18,
                          color: Color(0xFF999999),
                        ),
                      ),
                    );
                  }

                  // Fetch from both recipes and featured_recipes collections
                  return StreamBuilder<List<QuerySnapshot>>(
                    stream: FirebaseFirestore.instance
                        .collection('recipes')
                        .snapshots()
                        .asyncMap((recipesSnap) async {
                      final featuredSnap = await FirebaseFirestore.instance
                          .collection('featured_recipes')
                          .get();
                      return [recipesSnap, featuredSnap];
                    }).asBroadcastStream(),
                    builder: (context, combinedSnapshot) {
                      if (!combinedSnapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final allDocs = [
                        ...combinedSnapshot.data![0].docs,
                        ...combinedSnapshot.data![1].docs,
                      ];

                      final savedRecipes = allDocs
                          .where((doc) => favorites.contains(doc.id))
                          .toList();

                      if (savedRecipes.isEmpty) {
                        return const Center(
                          child: Text(
                            'No saved recipes found',
                            style: TextStyle(
                              fontSize: 18,
                              color: Color(0xFF999999),
                            ),
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: savedRecipes.length,
                        itemBuilder: (context, index) {
                          final recipe = savedRecipes[index].data()
                              as Map<String, dynamic>;
                          final recipeId = savedRecipes[index].id;

                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => DetailPage(
                                    recipeName: recipe['name'] ?? 'Recipe',
                                    recipeData: recipe,
                                    recipeId: recipeId,
                                  ),
                                ),
                              );
                            },
                            child: Card(
                              margin: const EdgeInsets.only(bottom: 16),
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Container(
                                height: 120,
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: _buildRecipeImage(
                                        recipe['imageUrl'] ??
                                            'images/Noimage.png',
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            recipe['name'] ?? 'Recipe',
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.schedule,
                                                size: 16,
                                                color: Color(0xFF999999),
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                '${recipe['cookingTime'] ?? 30} mins',
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  color: Color(0xFF999999),
                                                ),
                                              ),
                                              const SizedBox(width: 16),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFFF6B35)
                                                      .withOpacity(0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  recipe['category'] ?? '',
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color: Color(0xFFFF6B35),
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
      ),
    );
  }

  Widget _buildRecipeImage(dynamic path) {
    const fallback = 'images/Noimage.png';

    try {
      final normalized = (path ?? '').toString().trim();
      if (normalized.isEmpty) {
        return Image.asset(fallback, width: 96, height: 96, fit: BoxFit.cover);
      }

      final isRemote = normalized.startsWith('http');
      if (isRemote) {
        return Image.network(
          normalized,
          width: 96,
          height: 96,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Image.asset(fallback,
                width: 96, height: 96, fit: BoxFit.cover);
          },
        );
      }

      return Image.asset(
        normalized,
        width: 96,
        height: 96,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Image.asset(fallback,
              width: 96, height: 96, fit: BoxFit.cover);
        },
      );
    } catch (_) {
      return Image.asset(fallback, width: 96, height: 96, fit: BoxFit.cover);
    }
  }
}
