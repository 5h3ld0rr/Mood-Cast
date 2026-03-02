import 'package:flutter/material.dart';
import '../../theme.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080C14),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Search',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              // Search Bar
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: const TextField(
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.search, color: AppTheme.textMuted),
                    hintText: 'Search songs, artists, or moods',
                    hintStyle: TextStyle(color: AppTheme.textMuted),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 15),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Browse All',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.6,
                  children: [
                    _buildCategoryCard('Pop', Colors.pinkAccent),
                    _buildCategoryCard('Chill', Colors.blueAccent),
                    _buildCategoryCard('Indie', Colors.greenAccent),
                    _buildCategoryCard('Electronic', Colors.purpleAccent),
                    _buildCategoryCard('Rock', Colors.orangeAccent),
                    _buildCategoryCard('Jazz', Colors.brown),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryCard(String name, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Center(
        child: Text(
          name,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
