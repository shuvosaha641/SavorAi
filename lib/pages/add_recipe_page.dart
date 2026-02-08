import 'package:flutter/material.dart';
import 'package:recipeappflutter/services/auth_service.dart';
import 'package:recipeappflutter/services/database_service.dart';

class AddRecipePage extends StatefulWidget {
  const AddRecipePage({super.key});

  @override
  State<AddRecipePage> createState() => _AddRecipePageState();
}

class _AddRecipePageState extends State<AddRecipePage> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseService _databaseService = DatabaseService();
  final AuthService _authService = AuthService();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _caloriesController = TextEditingController();
  final TextEditingController _ingredientInputController =
      TextEditingController();
  final TextEditingController _instructionsController = TextEditingController();
  final TextEditingController _imageUrlController = TextEditingController();
  final TextEditingController _cookingTimeController = TextEditingController();

  List<String> _ingredientsList = [];

  String _selectedCategory = 'Breakfast';
  bool _isLoading = false;

  final List<String> _categories = [
    'Breakfast',
    'Lunch',
    'Dinner',
    'Dessert',
    'Snack',
    'Appetizer',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _caloriesController.dispose();
    _ingredientInputController.dispose();
    _instructionsController.dispose();
    _imageUrlController.dispose();
    _cookingTimeController.dispose();
    super.dispose();
  }

  Future<void> _submitRecipe() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_ingredientsList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one ingredient'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _databaseService.addRecipe(
        name: _nameController.text.trim(),
        description: _caloriesController.text.trim().isEmpty
            ? ''
            : _caloriesController.text.trim(),
        ingredients: _ingredientsList.join('|'),
        instructions: _instructionsController.text.trim(),
        imageUrl: _imageUrlController.text.trim().isEmpty
            ? 'images/Noimage.png'
            : _imageUrlController.text.trim(),
        category: _selectedCategory,
        cookingTime: int.parse(_cookingTimeController.text.trim()),
        userId: _authService.currentUser!.uid,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Recipe added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding recipe: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFFF6B35),
        title: const Text(
          'Add New Recipe',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFF5E1), Color(0xFFFFE8D6)],
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 8),
                  // Recipe Name
                  _buildLabeledField(
                    controller: _nameController,
                    label: 'Recipe Name',
                    icon: Icons.restaurant,
                    hint: 'e.g., Chocolate Cake',
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a recipe name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Calories (Optional)
                  _buildLabeledField(
                    controller: _caloriesController,
                    label: 'Calories (Optional)',
                    icon: Icons.fire_truck,
                    hint: 'e.g., 250 kcal',
                    maxLines: 1,
                    required: false,
                  ),
                  const SizedBox(height: 24),

                  // Ingredients (One by One)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(left: 4, bottom: 8),
                        child: Text(
                          'Ingredients (Add one by one)',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF555555),
                          ),
                        ),
                      ),
                      // Ingredient input field with add button
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _ingredientInputController,
                                decoration: InputDecoration(
                                  hintText: 'e.g., 2 cups flour',
                                  prefixIcon: const Icon(Icons.list,
                                      color: Color(0xFFFF6B35)),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                  contentPadding: const EdgeInsets.all(16),
                                  hintStyle: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: ElevatedButton(
                                onPressed: () {
                                  if (_ingredientInputController.text
                                      .trim()
                                      .isNotEmpty) {
                                    setState(() {
                                      _ingredientsList.add(
                                          _ingredientInputController.text
                                              .trim());
                                      _ingredientInputController.clear();
                                    });
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFF6B35),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child:
                                    const Icon(Icons.add, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Display added ingredients
                      if (_ingredientsList.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Added Ingredients:',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF555555),
                                ),
                              ),
                              const SizedBox(height: 8),
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _ingredientsList.length,
                                itemBuilder: (context, index) {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8.0),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            '${index + 1}. ${_ingredientsList[index]}',
                                            style: const TextStyle(
                                              color: Color(0xFF333333),
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              _ingredientsList.removeAt(index);
                                            });
                                          },
                                          child: const Icon(
                                            Icons.close,
                                            color: Color(0xFFFF6B35),
                                            size: 20,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Instructions
                  _buildLabeledField(
                    controller: _instructionsController,
                    label: 'Instructions',
                    icon: Icons.format_list_numbered,
                    hint: 'Step-by-step cooking instructions',
                    maxLines: 5,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter instructions';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Category Dropdown
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(left: 4, bottom: 8),
                        child: Text(
                          'Category',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF555555),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: DropdownButtonFormField<String>(
                          value: _selectedCategory,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            icon:
                                Icon(Icons.category, color: Color(0xFFFF6B35)),
                          ),
                          items: _categories.map((category) {
                            return DropdownMenuItem(
                              value: category,
                              child: Text(category),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedCategory = value!;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Cooking Time
                  _buildLabeledField(
                    controller: _cookingTimeController,
                    label: 'Cooking Time (minutes)',
                    icon: Icons.timer,
                    hint: 'e.g., 30',
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter cooking time';
                      }
                      if (int.tryParse(value) == null) {
                        return 'Please enter a valid number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Image URL (Optional)
                  _buildLabeledField(
                    controller: _imageUrlController,
                    label: 'Image URL (Optional)',
                    icon: Icons.image,
                    hint: 'https://example.com/image.jpg',
                    required: false,
                  ),
                  const SizedBox(height: 32),

                  // Submit Button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _submitRecipe,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6B35),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Add Recipe',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabeledField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
    int maxLines = 1,
    bool required = true,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF555555),
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              hintText: hint,
              prefixIcon: Icon(icon, color: const Color(0xFFFF6B35)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.all(16),
              hintStyle: TextStyle(
                color: Colors.grey[400],
                fontSize: 15,
              ),
            ),
            validator: validator,
          ),
        ),
      ],
    );
  }
}
