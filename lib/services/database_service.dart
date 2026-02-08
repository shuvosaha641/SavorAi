import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection reference
  final String _recipesCollection = 'recipes';

  // Add a new recipe
  Future<void> addRecipe({
    required String name,
    required String description,
    required String ingredients,
    required String instructions,
    required String imageUrl,
    required String category,
    required int cookingTime,
    required String userId,
  }) async {
    try {
      await _firestore.collection(_recipesCollection).add({
        'name': name,
        'description': description,
        'ingredients': ingredients,
        'instructions': instructions,
        'imageUrl': imageUrl,
        'category': category,
        'cookingTime': cookingTime,
        'userId': userId,
        'createdAt': FieldValue.serverTimestamp(),
        'likes': 0,
        'approved': false, // Requires admin approval
      });
    } catch (e) {
      rethrow;
    }
  }

  // Get all approved recipes
  Stream<QuerySnapshot> getRecipes() {
    return _firestore
        .collection(_recipesCollection)
        .where('approved', isEqualTo: true)
        .snapshots();
  }

  // Get featured/today's recipes (admin-curated)
  Stream<QuerySnapshot> getFeaturedRecipes() {
    return _firestore.collection('featured_recipes').limit(5).snapshots();
  }

  // Get all featured recipes (no limit)
  Stream<QuerySnapshot> getAllFeaturedRecipes() {
    return _firestore.collection('featured_recipes').snapshots();
  }

  // Get recipes by category
  Stream<QuerySnapshot> getRecipesByCategory(String category) {
    return _firestore
        .collection(_recipesCollection)
        .where('category', isEqualTo: category)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Get user's recipes
  Stream<QuerySnapshot> getUserRecipes(String userId) {
    return _firestore
        .collection(_recipesCollection)
        .where('userId', isEqualTo: userId)
        .snapshots();
  }

  // Update recipe
  Future<void> updateRecipe({
    required String recipeId,
    required Map<String, dynamic> data,
  }) async {
    try {
      await _firestore
          .collection(_recipesCollection)
          .doc(recipeId)
          .update(data);
    } catch (e) {
      rethrow;
    }
  }

  // Delete recipe
  Future<void> deleteRecipe(String recipeId) async {
    try {
      await _firestore.collection(_recipesCollection).doc(recipeId).delete();
    } catch (e) {
      rethrow;
    }
  }

  // Like/Unlike recipe
  Future<void> toggleLike(String recipeId, bool isLiked) async {
    try {
      await _firestore.collection(_recipesCollection).doc(recipeId).update({
        'likes': FieldValue.increment(isLiked ? 1 : -1),
      });
    } catch (e) {
      rethrow;
    }
  }

  // Search recipes
  Stream<QuerySnapshot> searchRecipes(String searchTerm) {
    return _firestore
        .collection(_recipesCollection)
        .where('name', isGreaterThanOrEqualTo: searchTerm)
        .where('name', isLessThanOrEqualTo: '$searchTerm\uf8ff')
        .snapshots();
  }

  // Add to favorites
  Future<void> addToFavorites(String userId, String recipeId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'favorites': FieldValue.arrayUnion([recipeId]),
      });
    } catch (e) {
      rethrow;
    }
  }

  // Remove from favorites
  Future<void> removeFromFavorites(String userId, String recipeId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'favorites': FieldValue.arrayRemove([recipeId]),
      });
    } catch (e) {
      rethrow;
    }
  }

  // Get favorite recipes
  Stream<DocumentSnapshot> getUserFavorites(String userId) {
    return _firestore.collection('users').doc(userId).snapshots();
  }

  // Create user document
  Future<void> createUserDocument(String userId, String email) async {
    try {
      await _firestore.collection('users').doc(userId).set({
        'email': email,
        'favorites': [],
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
  }

  // Rate a recipe
  Future<void> rateRecipe(String recipeId, String userId, double rating,
      {bool isFeatured = false}) async {
    try {
      final collection = isFeatured ? 'featured_recipes' : _recipesCollection;
      final recipeRef = _firestore.collection(collection).doc(recipeId);

      await _firestore.runTransaction((transaction) async {
        final recipeDoc = await transaction.get(recipeRef);

        if (!recipeDoc.exists) return;

        final data = recipeDoc.data() as Map<String, dynamic>;
        final ratings = Map<String, dynamic>.from(data['ratings'] ?? {});

        ratings[userId] = rating;

        // Calculate average rating
        final values =
            ratings.values.map((e) => (e as num).toDouble()).toList();
        final averageRating = values.isEmpty
            ? 0.0
            : values.reduce((a, b) => a + b) / values.length;

        transaction.update(recipeRef, {
          'ratings': ratings,
          'averageRating': averageRating,
          'ratingCount': ratings.length,
        });
      });
    } catch (e) {
      rethrow;
    }
  }

  // Get user's rating for a recipe
  Future<double?> getUserRating(String recipeId, String userId,
      {bool isFeatured = false}) async {
    try {
      final collection = isFeatured ? 'featured_recipes' : _recipesCollection;
      final doc = await _firestore.collection(collection).doc(recipeId).get();

      if (!doc.exists) return null;

      final data = doc.data() as Map<String, dynamic>;
      final ratings = Map<String, dynamic>.from(data['ratings'] ?? {});

      return ratings[userId]?.toDouble();
    } catch (e) {
      return null;
    }
  }

  // Get pending recipes (admin only)
  Stream<QuerySnapshot> getPendingRecipes() {
    return _firestore
        .collection(_recipesCollection)
        .where('approved', isEqualTo: false)
        .orderBy('createdAt', descending: false)
        .snapshots();
  }

  // Approve recipe (admin only)
  Future<void> approveRecipe(String recipeId) async {
    try {
      await _firestore.collection(_recipesCollection).doc(recipeId).update({
        'approved': true,
        'approvedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
  }

  // Reject recipe (admin only)
  Future<void> rejectRecipe(String recipeId) async {
    try {
      await _firestore.collection(_recipesCollection).doc(recipeId).delete();
    } catch (e) {
      rethrow;
    }
  }
}
