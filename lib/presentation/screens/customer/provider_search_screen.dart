import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../../services/supabase_config.dart';

class ProviderSearchScreen extends StatefulWidget {
  final String? initialQuery;
  final bool initialVoiceSearch;
  
  const ProviderSearchScreen({
    super.key, 
    this.initialQuery,
    this.initialVoiceSearch = false,
  });

  @override
  State<ProviderSearchScreen> createState() => _ProviderSearchScreenState();
}

class _ProviderSearchScreenState extends State<ProviderSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery != null) {
      _searchController.text = widget.initialQuery!;
      _performSearch(widget.initialQuery!);
    } else if (widget.initialVoiceSearch) {
      // Show voice search dialog
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showVoiceSearchDialog();
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults.clear();
      });
      return;
    }

    setState(() => _isSearching = true);

    try {
      // Search in provider_profiles and services tables
      final providers = await SupabaseConfig.client
          .from('provider_profiles')
          .select('*')
          .eq('verification_status', 'verified')
          .or('full_name.ilike.%$query%,services.cs.{$query}');

      setState(() {
        _searchResults = List<Map<String, dynamic>>.from(providers);
        _isSearching = false;
      });
    } catch (e) {
      setState(() => _isSearching = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Search error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF111418)),
          onPressed: () => Navigator.pop(context),
        ),
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search for services or providers...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: Color(0xFF5F758C)),
          ),
          onSubmitted: _performSearch,
        ),
        actions: [
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear, color: Color(0xFF5F758C)),
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _searchResults.clear();
                });
              },
            ),
        ],
      ),
      body: _isSearching
          ? const Center(child: CircularProgressIndicator())
          : _searchResults.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.search,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _searchController.text.isEmpty
                            ? 'Search for services or providers'
                            : 'No results found',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    final provider = _searchResults[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primaryBlue.withOpacity(0.1),
                          child: const Icon(
                            Icons.person,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                        title: Text(
                          provider['full_name'] ?? 'Provider',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          (provider['services'] as List?)?.join(', ') ?? 'Services',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          // Navigate to provider profile
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Provider profile coming soon!'),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
    );
  }
  
  void _showVoiceSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.mic, color: AppColors.primaryBlue),
            SizedBox(width: 8),
            Text('Voice Search'),
          ],
        ),
        content: const Text(
          'Voice search is coming soon! For now, please use text search.',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
