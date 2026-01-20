import 'package:flutter/material.dart';

class FavoriteProvider {
  final String id;
  final String name;
  final String category;
  final String imageUrl;
  final double rating;
  final int reviewCount;
  final bool isOnline;

  FavoriteProvider({
    required this.id,
    required this.name,
    required this.category,
    required this.imageUrl,
    required this.rating,
    required this.reviewCount,
    required this.isOnline,
  });
}

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<FavoriteProvider> _favorites = [];
  List<FavoriteProvider> _filteredFavorites = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFavorites() async {
    setState(() => _isLoading = true);

    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));

    // Mock data
    final mockFavorites = [
      FavoriteProvider(
        id: '1',
        name: 'QuickFix Plumbing',
        category: 'Home Repair',
        imageUrl: 'https://via.placeholder.com/150',
        rating: 4.8,
        reviewCount: 120,
        isOnline: true,
      ),
      FavoriteProvider(
        id: '2',
        name: 'Green Thumb Gardening',
        category: 'Landscaping',
        imageUrl: 'https://via.placeholder.com/150',
        rating: 4.9,
        reviewCount: 85,
        isOnline: false,
      ),
      FavoriteProvider(
        id: '3',
        name: 'Sparkle Cleaners',
        category: 'Cleaning Services',
        imageUrl: 'https://via.placeholder.com/150',
        rating: 4.7,
        reviewCount: 200,
        isOnline: true,
      ),
      FavoriteProvider(
        id: '4',
        name: 'TechWiz Support',
        category: 'IT Services',
        imageUrl: 'https://via.placeholder.com/150',
        rating: 5.0,
        reviewCount: 42,
        isOnline: false,
      ),
    ];

    setState(() {
      _favorites = mockFavorites;
      _filteredFavorites = mockFavorites;
      _isLoading = false;
    });
  }

  void _filterFavorites(String query) {
    if (query.isEmpty) {
      setState(() => _filteredFavorites = _favorites);
      return;
    }

    setState(() {
      _filteredFavorites = _favorites
          .where((provider) =>
              provider.name.toLowerCase().contains(query.toLowerCase()) ||
              provider.category.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  void _removeFromFavorites(FavoriteProvider provider) {
    setState(() {
      _favorites.removeWhere((p) => p.id == provider.id);
      _filteredFavorites.removeWhere((p) => p.id == provider.id);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text('${provider.name} removed from favorites'),
          ],
        ),
        backgroundColor: const Color(0xFF334155),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F7F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F7F6),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF181511)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'My Providers',
          style: TextStyle(
            color: Color(0xFF181511),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: TextField(
              controller: _searchController,
              onChanged: _filterFavorites,
              decoration: InputDecoration(
                hintText: 'Search your favorites...',
                hintStyle: const TextStyle(color: Color(0xFF897961)),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF897961)),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE6E1DB)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE6E1DB)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFEC9213), width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),

          // Favorites List
          Expanded(
            child: _isLoading
                ? _buildLoadingState()
                : _filteredFavorites.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _filteredFavorites.length,
                        itemBuilder: (context, index) {
                          return _buildProviderCard(_filteredFavorites[index]);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildProviderCard(FavoriteProvider provider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE6E1DB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('View ${provider.name} profile'),
                duration: const Duration(seconds: 1),
              ),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Avatar with online indicator
                Stack(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE6E1DB),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFE6E1DB)),
                        image: DecorationImage(
                          image: NetworkImage(provider.imageUrl),
                          fit: BoxFit.cover,
                          onError: (exception, stackTrace) {},
                        ),
                      ),
                      child: const Icon(
                        Icons.person,
                        size: 32,
                        color: Color(0xFF897961),
                      ),
                    ),
                    if (provider.isOnline)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(width: 16),

                // Provider Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        provider.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF181511),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        provider.category,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF897961),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.star,
                            size: 16,
                            color: Colors.amber,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            provider.rating.toString(),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF181511),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '(${provider.reviewCount} reviews)',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF897961),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Favorite Button
                IconButton(
                  onPressed: () => _removeFromFavorites(provider),
                  icon: const Icon(
                    Icons.favorite,
                    color: Color(0xFFEC9213),
                    size: 24,
                  ),
                  splashRadius: 24,
                  hoverColor: Colors.red.withOpacity(0.1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE6E1DB)),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFFE6E1DB),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 16,
                      width: 120,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE6E1DB),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 14,
                      width: 90,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE6E1DB),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFE6E1DB),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite_border,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          const Text(
            'No favorites yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF181511),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Start adding providers to your favorites',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF897961),
            ),
          ),
        ],
      ),
    );
  }
}
