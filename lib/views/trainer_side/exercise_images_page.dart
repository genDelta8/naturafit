import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:naturafit/services/user_provider.dart';
import 'package:naturafit/utilities/color_scheme.dart';
import 'package:naturafit/widgets/custom_focus_textfield.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ExerciseImagesPage extends StatefulWidget {
  const ExerciseImagesPage({super.key});

  @override
  State<ExerciseImagesPage> createState() => _ExerciseImagesPageState();
}

class _ExerciseImagesPageState extends State<ExerciseImagesPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<QueryDocumentSnapshot> _exercises = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    fetchImages();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> fetchImages() async {
    try {

      UserProvider userProvider = Provider.of<UserProvider>(context, listen: false);
      final userData = userProvider.userData;
      final trainerId = userData?['userId'];

      if (trainerId == null) {
        setState(() {
          _error = 'Trainer ID not found';
          _isLoading = false;
        });
        return;
      }


      setState(() {
        _isLoading = true;
        _error = null;
      });

      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('trainer_exercises')
          .doc(trainerId) // Replace with actual trainer ID
          .collection('all_exercises')
          .get();

      setState(() {
        _exercises = snapshot.docs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to fetch images: $e';
        _isLoading = false;
      });
    }
  }

  List<QueryDocumentSnapshot> get filteredExercises {
    if (_searchQuery.isEmpty) {
      // Only return exercises that have images
      return _exercises.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final imageUrls = (data['imageUrls'] as List?)?.cast<String>() ?? [];
        return imageUrls.isNotEmpty;
      }).toList();
    }
    
    return _exercises.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final name = data['name']?.toString().toLowerCase() ?? '';
      final imageUrls = (data['imageUrls'] as List?)?.cast<String>() ?? [];
      return name.contains(_searchQuery.toLowerCase()) && imageUrls.isNotEmpty;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: Border.all(
              color: theme.brightness == Brightness.light ? Colors.black : Colors.white,
              width: 1
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: Icon(
              Icons.chevron_left,
              color: theme.brightness == Brightness.light ? Colors.black : Colors.white
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: Text(
          l10n.exercise_images,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: theme.textTheme.titleLarge?.color,
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(16),
            child: CustomFocusTextField(
              label: '',
              hintText: l10n.search_images,
              prefixIcon: Icons.search,
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          Expanded(
            child: _buildContent(theme),
          ),
        ],
      ),
    );
  }

  Widget _buildContent([ThemeData? theme]) {
    final currentTheme = theme ?? Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: myBlue60));
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              l10n.failed_fetch_images(_error!),
              style: currentTheme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: fetchImages,
              child: Text(l10n.retry),
            ),
          ],
        ),
      );
    }

    if (_exercises.isEmpty) {
      return Center(
        child: Text(l10n.no_images_found),
      );
    }

    final exercises = filteredExercises;
    if (exercises.isEmpty) {
      return Center(
        child: Text(l10n.no_images_match),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: exercises.length,
      itemBuilder: (context, index) {
        final data = exercises[index].data() as Map<String, dynamic>;
        final imageUrls = (data['imageUrls'] as List?)?.cast<String>() ?? [];
        final exerciseName = data['name'] ?? l10n.unnamed_exercise;

        return Container(
          decoration: BoxDecoration(
            color: currentTheme.cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: currentTheme.shadowColor.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: CachedNetworkImage(
                    imageUrl: imageUrls[0],
                    fit: BoxFit.cover,
                    width: double.infinity,
                    placeholder: (context, url) => Container(
                      color: myGrey20,
                      child: const Center(
                        child: CircularProgressIndicator(color: myGrey30),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: myGrey20,
                      child: const Icon(Icons.fitness_center, color: myGrey60),
                    ),
                  ),
                  
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  exerciseName,
                  style: currentTheme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
} 