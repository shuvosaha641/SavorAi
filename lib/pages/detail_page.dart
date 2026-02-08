import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:recipeappflutter/services/widget_support.dart';
import 'package:recipeappflutter/services/database_service.dart';
import 'package:recipeappflutter/services/auth_service.dart';

class DetailPage extends StatefulWidget {
  final String recipeName;
  final Map<String, dynamic> recipeData;
  final String recipeId;

  const DetailPage({
    super.key,
    this.recipeName = 'Recipe',
    this.recipeData = const {},
    this.recipeId = '',
  });

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  final DatabaseService _databaseService = DatabaseService();
  final AuthService _authService = AuthService();
  bool _isFavorite = false;
  bool _isLoading = true;
  double? _userRating;
  bool _isFeatured = false;

  @override
  void initState() {
    super.initState();
    _checkIfFavorite();
    _checkIfFeaturedAndLoadRating();
  }

  Future<void> _checkIfFeaturedAndLoadRating() async {
    if (widget.recipeId.isNotEmpty) {
      try {
        final featuredDoc = await FirebaseFirestore.instance
            .collection('featured_recipes')
            .doc(widget.recipeId)
            .get();
        _isFeatured = featuredDoc.exists;
      } catch (e) {
        _isFeatured = false;
      }
    }

    final userId = _authService.currentUser?.uid;
    if (userId != null && widget.recipeId.isNotEmpty) {
      final rating = await _databaseService.getUserRating(
        widget.recipeId,
        userId,
        isFeatured: _isFeatured,
      );
      if (mounted) {
        setState(() => _userRating = rating);
      }
    }
  }

  Future<void> _rateRecipe(double rating) async {
    final userId = _authService.currentUser?.uid;
    if (userId == null || widget.recipeId.isEmpty) return;

    try {
      await _databaseService.rateRecipe(
        widget.recipeId,
        userId,
        rating,
        isFeatured: _isFeatured,
      );
      setState(() => _userRating = rating);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Rated ${rating.toStringAsFixed(1)} stars')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error rating recipe: $e')),
        );
      }
    }
  }

  Future<void> _checkIfFavorite() async {
    final userId = _authService.currentUser?.uid;
    if (userId == null || widget.recipeId.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }

    final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();

    if (userDoc.exists) {
      final favorites = List<String>.from(userDoc.data()?['favorites'] ?? []);
      setState(() {
        _isFavorite = favorites.contains(widget.recipeId);
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleFavorite() async {
    final userId = _authService.currentUser?.uid;
    if (userId == null || widget.recipeId.isEmpty) return;

    setState(() => _isFavorite = !_isFavorite);

    try {
      if (_isFavorite) {
        await _databaseService.addToFavorites(userId, widget.recipeId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Added to saved recipes')),
          );
        }
      } else {
        await _databaseService.removeFromFavorites(userId, widget.recipeId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Removed from saved recipes')),
          );
        }
      }
    } catch (e) {
      setState(() => _isFavorite = !_isFavorite);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final expandedHeight = MediaQuery.of(context).size.height * 0.38;

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              automaticallyImplyLeading: false,
              backgroundColor: Colors.transparent,
              elevation: 0,
              expandedHeight: expandedHeight,
              pinned: false,
              floating: false,
              flexibleSpace: LayoutBuilder(
                builder: (context, constraints) {
                  final percent = ((constraints.maxHeight - kToolbarHeight) /
                          (expandedHeight - kToolbarHeight))
                      .clamp(0.0, 1.0);
                  final opacity = percent;

                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      Opacity(
                        opacity: opacity,
                        child: _buildHeaderImage(
                          widget.recipeData['imageUrl'] ?? 'images/Noimage.png',
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withOpacity(0.25 * opacity),
                              Colors.black.withOpacity(0.05 * opacity),
                            ],
                          ),
                        ),
                      ),
                      SafeArea(
                        child: Align(
                          alignment: Alignment.topLeft,
                          child: GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              margin:
                                  const EdgeInsets.only(top: 12.0, left: 16.0),
                              padding: const EdgeInsets.all(6.0),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.65),
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                              child: const Icon(
                                Icons.arrow_back_sharp,
                                color: Colors.black,
                                size: 22.0,
                              ),
                            ),
                          ),
                        ),
                      ),
                      SafeArea(
                        child: Align(
                          alignment: Alignment.topRight,
                          child: GestureDetector(
                            onTap: _toggleFavorite,
                            child: Container(
                              margin:
                                  const EdgeInsets.only(top: 12.0, right: 16.0),
                              padding: const EdgeInsets.all(6.0),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.65),
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Icon(
                                      _isFavorite
                                          ? Icons.favorite
                                          : Icons.favorite_border,
                                      color: _isFavorite
                                          ? Colors.red
                                          : Colors.black,
                                      size: 22.0,
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ];
        },
        body: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30.0),
              topRight: Radius.circular(30.0),
            ),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.recipeName,
                    style: AppWidget.healineTextstyle(30.0)),
                const SizedBox(height: 12.0),
                _buildRatingSection(),
                const SizedBox(height: 20.0),
                Row(
                  children: [
                    Flexible(
                      child: Container(
                        height: 110,
                        padding: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          color: const Color(0xffddf1e6),
                          borderRadius: BorderRadius.circular(20.0),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.asset(
                              "images/alarm.png",
                              height: 45,
                              width: 45,
                              fit: BoxFit.cover,
                              color: const Color(0xff5ab38a),
                            ),
                            const SizedBox(height: 4.0),
                            Text(
                                "${widget.recipeData['cookingTime'] ?? 30} min",
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    color: Color(0xff5ab38a),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12.0)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10.0),
                    Flexible(
                      child: Container(
                        height: 110,
                        padding: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          color: const Color(0xfffdf0db),
                          borderRadius: BorderRadius.circular(20.0),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.asset(
                              "images/smiley.png",
                              height: 45,
                              width: 45,
                              fit: BoxFit.cover,
                            ),
                            const SizedBox(height: 4.0),
                            Flexible(
                              child: Text(
                                  (widget.recipeData['category'] ?? 'MEDIUM')
                                      .toUpperCase(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      color: Color(0xffe4b46b),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11.0)),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10.0),
                    Flexible(
                      child: Container(
                        height: 110,
                        padding: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          color: const Color(0xffe7eefa),
                          borderRadius: BorderRadius.circular(20.0),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.asset(
                              "images/fire.png",
                              height: 45,
                              width: 45,
                              fit: BoxFit.cover,
                              color: const Color(0xff7fb1dc),
                            ),
                            const SizedBox(height: 4.0),
                            Flexible(
                              child: Text(
                                widget.recipeData['description'] ?? '??',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    color: Color(0xff7fb1dc),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 9.0),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20.0),
                Text("Ingredients", style: AppWidget.healineTextstyle(25.0)),
                const SizedBox(height: 10.0),
                _buildNumberedIngredients(
                    widget.recipeData['ingredients'] ?? ''),
                const SizedBox(height: 20.0),
                Text("Directions:", style: AppWidget.healineTextstyle(25.0)),
                const SizedBox(height: 10.0),
                Text(
                    (widget.recipeData['instructions'] ?? 'No instructions')
                        .replaceAll('\\n', '\n'),
                    style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 16.0,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 30.0),
                Text("Recommended", style: AppWidget.healineTextstyle(25.0)),
                const SizedBox(height: 10.0),
                _buildRecommendedSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNumberedIngredients(String ingredientsString) {
    if (ingredientsString.isEmpty) {
      return const Text(
        'No ingredients',
        style: TextStyle(
          color: Colors.black87,
          fontSize: 16.0,
          fontWeight: FontWeight.w500,
        ),
      );
    }

    final ingredients = ingredientsString.split('|');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: ingredients.asMap().entries.map((entry) {
        final index = entry.key + 1;
        final ingredient = entry.value.trim();
        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Text(
            '$index) $ingredient',
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 16.0,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildHeaderImage(dynamic path) {
    const fallback = 'images/Noimage.png';

    try {
      final normalized = (path ?? '').toString().trim();
      if (normalized.isEmpty) {
        return Image.asset(fallback, fit: BoxFit.cover);
      }

      final isRemote = normalized.startsWith('http');
      if (isRemote) {
        return Image.network(
          normalized,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Image.asset(fallback, fit: BoxFit.cover);
          },
        );
      }

      return Image.asset(
        normalized,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Image.asset(fallback, fit: BoxFit.cover);
        },
      );
    } catch (_) {
      return Image.asset(fallback, fit: BoxFit.cover);
    }
  }

  Widget _buildRatingSection() {
    final averageRating =
        (widget.recipeData['averageRating'] ?? 0.0).toDouble();
    final ratingCount = widget.recipeData['ratingCount'] ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            ...List.generate(5, (index) {
              return Icon(
                index < averageRating.round() ? Icons.star : Icons.star_border,
                color: Colors.amber,
                size: 24,
              );
            }),
            const SizedBox(width: 8),
            Text(
              '${averageRating.toStringAsFixed(1)} ($ratingCount)',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Text(
          'Your Rating:',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: List.generate(5, (index) {
            final starValue = (index + 1).toDouble();
            return GestureDetector(
              onTap: () => _rateRecipe(starValue),
              child: Icon(
                _userRating != null && starValue <= _userRating!
                    ? Icons.star
                    : Icons.star_border,
                color: Colors.amber,
                size: 32,
              ),
            );
          }),
        ),
      ],
    );
  }

  // --- Simple ingredient-based recommendations ---
  Set<String> _tokensFromString(String s) {
    final normalized = s.toLowerCase().trim();
    if (normalized.isEmpty) return {};

    // pipe separator 
    if (normalized.contains('|')) {
      return normalized
          .split('|')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toSet();
    }

    // comma separator
    if (normalized.contains(',')) {
      return normalized
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toSet();
    }

    //newline separator
    if (normalized.contains('\n')) {
      return normalized
          .split('\n')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toSet();
    }

    // Single ingredient or space-separated words
    return normalized
        .split(RegExp(r'\s+'))
        .where((e) => e.length > 2) 
        .toSet();
  }

  double _jaccard(Set<String> a, Set<String> b) {
    if (a.isEmpty || b.isEmpty) return 0.0;
    final inter = a.intersection(b).length;
    final uni = a.union(b).length;
    return inter / uni;
  }

  Widget _buildRecommendedSection() {
    final currentIngredients =
        (widget.recipeData['ingredients'] ?? '') as String;
    final baseTokens = _tokensFromString(currentIngredients);

    if (baseTokens.isEmpty) {
      return const Text('No similar recipes yet');
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('recipes').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 80,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final docs = snapshot.data!.docs;

        if (docs.isEmpty) {
          return const SizedBox.shrink();
        }

        final scored = <Map<String, dynamic>>[];

        for (final doc in docs) {
          final data = doc.data() as Map<String, dynamic>;

          // Exclude the same recipe by ID
          if (widget.recipeId.isNotEmpty && doc.id == widget.recipeId) {
            continue;
          }

          final tokens =
              _tokensFromString((data['ingredients'] ?? '') as String);
          final intersection = baseTokens.intersection(tokens);

          if (intersection.isNotEmpty) {
            final sim = _jaccard(baseTokens, tokens);
            scored.add({'doc': doc, 'data': data, 'score': sim});
          }
        }

        if (scored.isEmpty) {
          return const SizedBox.shrink();
        }

        scored.sort(
            (a, b) => (b['score'] as double).compareTo(a['score'] as double));
        final top = scored.take(6).toList();

        return SizedBox(
          height: 210,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: top.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final item = top[index];
              final data = item['data'] as Map<String, dynamic>;
              final doc = item['doc'] as QueryDocumentSnapshot;
              final imagePath = data['imageUrl'] ?? 'images/Noimage.png';
              final name = data['name'] ?? 'Recipe';

              return GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DetailPage(
                      recipeName: name,
                      recipeData: data,
                      recipeId: doc.id,
                    ),
                  ),
                ),
                child: Container(
                  width: 160,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x11000000),
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                        child: SizedBox(
                          height: 110,
                          width: double.infinity,
                          child: _buildHeaderImage(imagePath),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
                        child: Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
