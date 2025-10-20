import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/quest.dart';
import '../models/user_progress.dart';
import '../models/badge.dart' as badge_model;
import '../services/quest_service.dart';
import '../widgets/quest_card.dart';
import '../widgets/badge_widget.dart';
import 'quest_detail_screen.dart';

/// Main home screen with Google Maps and quest list
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  GoogleMapController? _mapController;
  Quest? _selectedQuest;
  bool _showQuestList = true;
  UserProgress _userProgress = UserProgress.empty();
  List<Quest> _quests = [];
  bool _isLoading = true;
  Map<String, dynamic>? _statistics;
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      // Load quests from JSON
      final quests = await QuestService.loadQuests();
      final stats = QuestService.getStatistics(quests);
      
      // Load user progress from LocalStorage (for now, empty)
      final progress = UserProgress.empty();
      
      setState(() {
        _quests = quests;
        _statistics = stats;
        _userProgress = progress;
        _isLoading = false;
      });
      
      print('✅ Loaded ${quests.length} quests from JSON');
      print('📊 Statistics: $stats');
    } catch (e) {
      print('❌ Error loading quests: $e');
      setState(() => _isLoading = false);
    }
  }
  
  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }
  
  Set<Marker> _buildMarkers() {
    return _quests.map((quest) {
      final isCompleted = _userProgress.isQuestCompleted(quest.id);
      
      return Marker(
        markerId: MarkerId(quest.id),
        position: quest.coordinates, // Uses real GPS coordinates from local_town
        icon: BitmapDescriptor.defaultMarkerWithHue(
          isCompleted ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueOrange,
        ),
        infoWindow: InfoWindow(
          title: quest.nameIt,
          snippet: quest.localTown ?? quest.location.name,
          onTap: () => _onQuestSelected(quest),
        ),
        onTap: () => _onQuestSelected(quest),
      );
    }).toSet();
  }
  
  void _onQuestSelected(Quest quest) {
    setState(() {
      _selectedQuest = quest;
    });
    
    // Animate camera to quest location
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(quest.location.coordinates, 14),
    );
  }
  
  void _openQuestDetail(Quest quest) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => QuestDetailScreen(
          quest: quest,
          isCompleted: _userProgress.isQuestCompleted(quest.id),
          onComplete: () {
            setState(() {
              _userProgress = _userProgress.copyWithCompletedQuest(quest.id);
            });
          },
        ),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final completedCount = _userProgress.completedQuestIds.length;
    
    // Show loading indicator
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Seasonal Quest Explorer'),
          backgroundColor: Colors.green,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.green),
              SizedBox(height: 16),
              Text('Loading seasonal quests...', style: TextStyle(fontSize: 16)),
            ],
          ),
        ),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Seasonal Quest Explorer'),
        backgroundColor: Colors.green,
        actions: [
          // Progress indicator
          Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                '$completedCount/${_quests.length}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Statistics Banner
          if (_statistics != null)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: Colors.blue.shade50,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatChip('📦 Total', '${_statistics!['total']}', Colors.blue),
                  _buildStatChip('🌱 In Season', '${_statistics!['in_season']}', Colors.green),
                  _buildStatChip('🍎 Fruits', '${_statistics!['fruits']}', Colors.red),
                  _buildStatChip('🥕 Vegetables', '${_statistics!['vegetables']}', Colors.orange),
                ],
              ),
            ),
          // Badge Showcase
          Container(
            color: Colors.green.shade50,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Row(
                    children: [
                      Icon(Icons.emoji_events, color: Colors.amber, size: 24),
                      SizedBox(width: 8),
                      Text(
                        'Your Badges',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                // Badge showcase
                BadgeShowcase(
                  badges: _generateBadges(),
                  progressMap: _generateProgressMap(),
                ),
              ],
            ),
          ),
          
          // Map / Quest List Toggle
          Container(
            padding: EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => setState(() => _showQuestList = false),
                    icon: Icon(Icons.map),
                    label: Text('Map View'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: !_showQuestList ? Colors.green : Colors.grey.shade300,
                      foregroundColor: !_showQuestList ? Colors.white : Colors.black,
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => setState(() => _showQuestList = true),
                    icon: Icon(Icons.list),
                    label: Text('Quest List'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _showQuestList ? Colors.green : Colors.grey.shade300,
                      foregroundColor: _showQuestList ? Colors.white : Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Main Content: Map or Quest List
          Expanded(
            child: _showQuestList ? _buildQuestList() : _buildMap(),
          ),
        ],
      ),
      floatingActionButton: _selectedQuest != null
          ? FloatingActionButton.extended(
              onPressed: () => _openQuestDetail(_selectedQuest!),
              icon: Icon(Icons.info),
              label: Text('View Details'),
              backgroundColor: Colors.green,
            )
          : null,
    );
  }
  
  Widget _buildStatChip(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
        ),
      ],
    );
  }
  
  Widget _buildMap() {
    return GoogleMap(
      onMapCreated: _onMapCreated,
      initialCameraPosition: CameraPosition(
        target: LatLng(38.7, 16.0), // Calabria center
        zoom: 9.0,
      ),
      markers: _buildMarkers(),
      mapType: MapType.hybrid,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: true,
      onTap: (LatLng position) {
        setState(() {
          _selectedQuest = null;
        });
      },
    );
  }
  
  Widget _buildQuestList() {
    final currentMonth = DateTime.now().month;
    final inSeasonQuests = _quests.where((q) => q.isAvailableInMonth(currentMonth)).toList();
    final outOfSeasonQuests = _quests.where((q) => !q.isAvailableInMonth(currentMonth)).toList();
    
    return ListView(
      padding: EdgeInsets.symmetric(vertical: 8),
      children: [
        // In Season Section
        if (inSeasonQuests.isNotEmpty) ...[
          Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              '🌱 In Season Now (${inSeasonQuests.length})',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ),
          ...inSeasonQuests.map((quest) => QuestCard(
            quest: quest,
            isCompleted: _userProgress.isQuestCompleted(quest.id),
            onTap: () => _openQuestDetail(quest),
          )),
        ],
        
        // Out of Season Section
        if (outOfSeasonQuests.isNotEmpty) ...[
          Padding(
            padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Text(
              '❄️ Out of Season (${outOfSeasonQuests.length})',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          ...outOfSeasonQuests.map((quest) => QuestCard(
            quest: quest,
            isCompleted: _userProgress.isQuestCompleted(quest.id),
            onTap: () => _openQuestDetail(quest),
          )),
        ],
      ],
    );
  }

  /// Generate sample badges for demonstration
  List<badge_model.Badge> _generateBadges() {
    final completedCount = _userProgress.completedQuestIds.length;
    
    return [
      badge_model.Badge(
        id: 'first-quest',
        name: 'First Quest',
        description: 'Complete your first seasonal quest',
        icon: '🌟',
        type: badge_model.BadgeType.collector,
        requirementCount: 1,
        isUnlocked: completedCount >= 1,
        unlockedAt: completedCount >= 1 ? DateTime.now().subtract(Duration(days: 5)) : null,
      ),
      badge_model.Badge(
        id: 'collector',
        name: 'Collector',
        description: 'Complete 5 seasonal quests',
        icon: '📚',
        type: badge_model.BadgeType.collector,
        requirementCount: 5,
        isUnlocked: completedCount >= 5,
        unlockedAt: completedCount >= 5 ? DateTime.now().subtract(Duration(days: 2)) : null,
      ),
      badge_model.Badge(
        id: 'explorer',
        name: 'Explorer',
        description: 'Complete 10 seasonal quests',
        icon: '🗺️',
        type: badge_model.BadgeType.explorer,
        requirementCount: 10,
        isUnlocked: completedCount >= 10,
        unlockedAt: completedCount >= 10 ? DateTime.now() : null,
      ),
      badge_model.Badge(
        id: 'master',
        name: 'Master',
        description: 'Complete all quests',
        icon: '👑',
        type: badge_model.BadgeType.master,
        requirementCount: _quests.length,
        isUnlocked: completedCount >= _quests.length,
        unlockedAt: completedCount >= _quests.length ? DateTime.now() : null,
      ),
    ];
  }

  /// Generate progress map for badges
  Map<String, int> _generateProgressMap() {
    final completedCount = _userProgress.completedQuestIds.length;
    
    return {
      'first-quest': completedCount,
      'collector': completedCount,
      'explorer': completedCount,
      'master': completedCount,
    };
  }
}

