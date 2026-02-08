import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:recipeappflutter/pages/detail_page.dart';
import 'package:recipeappflutter/pages/add_recipe_page.dart';
import 'package:recipeappflutter/pages/saved_recipes_page.dart';
import 'package:recipeappflutter/pages/user_recipes_page.dart';
import 'package:recipeappflutter/pages/all_featured_recipes_page.dart';
import 'package:recipeappflutter/pages/all_recipes_page.dart';
import 'package:recipeappflutter/pages/chat_page.dart';
import 'package:recipeappflutter/services/auth_service.dart';
import 'package:recipeappflutter/services/database_service.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final AuthService _authService = AuthService();
  final DatabaseService _databaseService = DatabaseService();
  String _searchQuery = '';

  void _logout() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFFF6B35), Color(0xFFFFA500)],
                    ),
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: const [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: Colors.white,
                        child: Icon(Icons.logout,
                            color: Color(0xFFFF6B35), size: 28),
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Logout',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  child: Column(
                    children: const [
                      Text(
                        'Are you sure you want to logout?',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF333333),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'You can always log back in to continue exploring recipes.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF777777),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                                color: Color(0xFFFF6B35), width: 1.4),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(
                              color: Color(0xFFFF6B35),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF6B35),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 4,
                          ),
                          onPressed: () async {
                            await _authService.signOut();
                            if (mounted) {
                              Navigator.pop(context);
                              // Auth state change will automatically redirect via AuthWrapper
                            }
                          },
                          child: const Text(
                            'Logout',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFFF6B35), Color(0xFFFFA500)],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const Text(
                      '🍳 SavorAI',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _authService.currentUser?.email ?? '',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              ListTile(
                leading: const Icon(Icons.favorite, color: Color(0xFFFF6B35)),
                title: const Text('Saved Recipes'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SavedRecipesPage(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.menu_book, color: Color(0xFFFF6B35)),
                title: const Text('Your Recipes'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const UserRecipesPage(),
                    ),
                  );
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout, color: Color(0xFFFF6B35)),
                title: const Text('Logout'),
                onTap: () {
                  Navigator.pop(context);
                  _logout();
                },
              ),
            ],
          ),
        ),
        appBar: AppBar(
          elevation: 0,
          backgroundColor: const Color(0xFFFF6B35),
          iconTheme: const IconThemeData(color: Colors.white),
          title: const Text(
            '🍳 SavorAI',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.white),
              onPressed: _logout,
              tooltip: 'Logout',
            ),
          ],
        ),
        body: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFFFF5E1), Color(0xFFFFE8D6)],
                ),
              ),
              child: SingleChildScrollView(
                child: Container(
                  margin: const EdgeInsets.only(
                      top: 20.0, left: 16.0, right: 16.0, bottom: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Greeting Section
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF6B35), Color(0xFFFFA500)],
                          ),
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Text(
                              'What would you like to cook?',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Explore delicious recipes today!',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Search Bar
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: TextField(
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value.toLowerCase();
                            });
                          },
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            hintText: 'Search recipes...',
                            prefixIcon: const Icon(Icons.search,
                                color: Color(0xFFFF6B35)),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 14),
                            hintStyle: const TextStyle(
                              color: Colors.grey,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Show different content based on search
                      if (_searchQuery.isEmpty) ...[
                        // Today's Recipes Section (only show when not searching)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Today\'s Favorites',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF333333),
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                print('See all button tapped');
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const AllFeaturedRecipesPage(),
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF6B35),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  'See all',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Horizontal Recipe Cards from Database
                        StreamBuilder<QuerySnapshot>(
                          stream: _databaseService.getFeaturedRecipes(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const SizedBox(
                                height: 280,
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: Color(0xFFFF6B35),
                                  ),
                                ),
                              );
                            }

                            if (snapshot.hasError ||
                                !snapshot.hasData ||
                                snapshot.data!.docs.isEmpty) {
                              return const SizedBox(
                                height: 280,
                                child: Center(
                                  child: Text(
                                    'No featured recipes today',
                                    style: TextStyle(
                                      color: Color(0xFF999999),
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              );
                            }

                            final featuredRecipes = snapshot.data!.docs;

                            return SizedBox(
                              height: 280,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: featuredRecipes.length,
                                separatorBuilder: (context, index) =>
                                    const SizedBox(width: 16),
                                itemBuilder: (context, index) {
                                  final recipe = featuredRecipes[index].data()
                                      as Map<String, dynamic>;
                                  final recipeId = featuredRecipes[index].id;

                                  return GestureDetector(
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => DetailPage(
                                            recipeName:
                                                recipe['name'] ?? 'Recipe',
                                            recipeData: recipe,
                                            recipeId: recipeId,
                                          ),
                                        ),
                                      );
                                    },
                                    child: _buildRecipeCard(
                                      recipe['name'] ?? 'Recipe',
                                      (recipe['imageUrl'] ??
                                              'images/Noimage.png')
                                          .toString()
                                          .trim(),
                                      '${recipe['cookingTime'] ?? 30} mins',
                                      const Color(0xFFFF6B35),
                                      (recipe['averageRating'] ?? 0.0)
                                          .toDouble(),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 28),
                      ],

                      // Recommended Section
                      if (_searchQuery.isEmpty)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Recipes',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF333333),
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const AllRecipesPage(),
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF6B35),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  'See all',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      if (_searchQuery.isNotEmpty)
                        const Text(
                          'Search Results',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF333333),
                          ),
                        ),
                      const SizedBox(height: 14),

                      // Recipe Items from Firestore
                      StreamBuilder<QuerySnapshot>(
                        stream: _databaseService.getRecipes(),
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Text(
                                  'Error loading recipes: ${snapshot.error}',
                                  style: const TextStyle(color: Colors.red),
                                ),
                              ),
                            );
                          }

                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(32.0),
                                child: CircularProgressIndicator(
                                  color: Color(0xFFFF6B35),
                                ),
                              ),
                            );
                          }

                          if (!snapshot.hasData ||
                              snapshot.data!.docs.isEmpty) {
                            if (_searchQuery.isNotEmpty) {
                              return Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(32.0),
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.search,
                                        size: 64,
                                        color: Colors.grey[400],
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'No recipes found for "$_searchQuery"',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF666666),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      const Text(
                                        'Try searching for something else',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Color(0xFF999999),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.all(32.0),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.restaurant_menu,
                                      size: 64,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'No recipes yet!',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF666666),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Tap the + button to add your first recipe',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Color(0xFF999999),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }

                          final allRecipes = snapshot.data!.docs;

                          // Filter recipes based on search query
                          List<QueryDocumentSnapshot> filteredRecipes;
                          if (_searchQuery.isEmpty) {
                            // Show 2-3 random recipes when not searching
                            final shuffled =
                                List<QueryDocumentSnapshot>.from(allRecipes)
                                  ..shuffle();
                            filteredRecipes = shuffled.take(3).toList();
                          } else {
                            filteredRecipes = allRecipes.where((recipe) {
                              final recipeName = (recipe.data()
                                      as Map<String, dynamic>)['name'] ??
                                  '';
                              return recipeName
                                  .toString()
                                  .toLowerCase()
                                  .contains(_searchQuery);
                            }).toList();
                          }

                          // Check if filtered results are empty
                          if (filteredRecipes.isEmpty) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.all(32.0),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.search,
                                      size: 64,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No recipes found for "$_searchQuery"',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF666666),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Try searching for something else',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Color(0xFF999999),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }

                          return Column(
                            children: filteredRecipes.map((recipe) {
                              final data =
                                  recipe.data() as Map<String, dynamic>;
                              final recipeId = recipe.id;

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: GestureDetector(
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => DetailPage(
                                          recipeName: data['name'] ?? 'Recipe',
                                          recipeData: data,
                                          recipeId: recipeId,
                                        ),
                                      ),
                                    );
                                  },
                                  child: FoodWidget(
                                    name: data['name'] ?? 'Untitled Recipe',
                                    imagePath: data['imageUrl'] ??
                                        'images/Noimage.png',
                                    author: 'Recipe Creator',
                                    time: '${data['cookingTime'] ?? 30} mins',
                                    difficulty:
                                        data['category']?.toUpperCase() ??
                                            'MEDIUM',
                                    rating: (data['averageRating'] ?? 0.0)
                                        .toDouble(),
                                  ),
                                ),
                              );
                            }).toList(),
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 20,
              left: 16,
              child: _buildChatFab(),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const AddRecipePage(),
              ),
            );
          },
          backgroundColor: const Color(0xFFFF6B35),
          child: const Icon(Icons.add, color: Colors.white, size: 32),
        ),
      ),
    );
  }

  Widget _buildChatFab() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ChatPage()),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Container(
          width: 56,
          height: 56,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [Color(0xFF6C63FF), Color(0xFF00C2FF)],
            ),
          ),
          child: const Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                Icons.smart_toy_outlined,
                color: Colors.white,
                size: 28,
              ),
              Positioned(
                bottom: 8,
                right: 10,
                child: CircleAvatar(
                  radius: 6,
                  backgroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecipeCard(
    String name,
    String imagePath,
    String time,
    Color accentColor,
    double rating,
  ) {
    return Container(
      width: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: _buildRecipeImage(
              imagePath,
              height: 280,
              width: 200,
            ),
          ),
          Container(
            height: 280,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.7),
                ],
              ),
            ),
          ),
          if (rating > 0)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      rating.toStringAsFixed(1),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: accentColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.schedule,
                            color: Colors.white, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          time,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecipeImage(dynamic path,
      {required double height, required double width}) {
    const fallback = 'images/Noimage.png';

    Image errorFallback() => Image.asset(
          fallback,
          height: height,
          width: width,
          fit: BoxFit.cover,
        );

    try {
      final normalized = (path ?? '').toString().trim();
      if (normalized.isEmpty) return errorFallback();

      final isRemote = normalized.startsWith('http');
      if (isRemote) {
        return Image.network(
          normalized,
          height: height,
          width: width,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => errorFallback(),
        );
      }

      return Image.asset(
        normalized,
        height: height,
        width: width,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => errorFallback(),
      );
    } catch (_) {
      return errorFallback();
    }
  }
}

class FoodWidget extends StatelessWidget {
  const FoodWidget({
    super.key,
    required this.name,
    required this.imagePath,
    required this.author,
    required this.time,
    required this.difficulty,
    this.rating = 0.0,
  });
  final String name;
  final String imagePath;
  final String author;
  final String time;
  final String difficulty;
  final double rating;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 130,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Image Section
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              bottomLeft: Radius.circular(16),
            ),
            child: Image.asset(
              imagePath,
              height: 130,
              width: 130,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 16),

          // Content Section
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Recipe Name
                  Flexible(
                    child: Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF333333),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Star Rating (always show)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.star,
                        color: rating > 0 ? Colors.amber : Colors.grey[400],
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        rating.toStringAsFixed(1),
                        style: const TextStyle(
                          color: Color(0xFF666666),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Author Name
                  Flexible(
                    child: Text(
                      'By $author',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF999999),
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Time and Difficulty
                  Flexible(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Time
                        Flexible(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.schedule,
                                color: Color(0xFFFF6B35),
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  time,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Color(0xFF666666),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Difficulty Badge
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFE8D6),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: const Color(0xFFFF6B35),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              difficulty,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFFFF6B35),
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}
