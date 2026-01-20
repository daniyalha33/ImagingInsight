// lib/screens/mobile/profile_screen.dart
import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback onLogout;

  const ProfileScreen({
    Key? key,
    required this.onLogout,
  }) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool isLoading = true;
  String? errorMessage;

  // User data
  String userName = '';
  String userEmail = '';
  String userRole = '';
  String? profileImage;

  // Status data
  String statusMessage = '';
  String availability = 'available';
  String customEmoji = '';

  // Stats data
  int totalPoints = 0;
  int classesEnrolled = 0;
  int assessmentsCompleted = 0;
  int averageScore = 0;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final data = await ApiService.getUserProfile();

      if (data['success'] == false) {
        throw Exception(data['message'] ?? 'Failed to load profile');
      }

      final user = data['user'];
      final status = data['status'];
      final stats = data['stats'];

      setState(() {
        userName = user['name'] ?? '';
        userEmail = user['email'] ?? '';
        userRole = user['role'] ?? '';
        profileImage = user['profileImage'];

        statusMessage = status['message'] ?? '';
        availability = status['availability'] ?? 'available';
        customEmoji = status['customEmoji'] ?? '';

        totalPoints = stats['totalPoints'] ?? 0;
        classesEnrolled = stats['classesEnrolled'] ?? 0;
        assessmentsCompleted = stats['assessmentsCompleted'] ?? 0;
        averageScore = stats['averageScore'] ?? 0;

        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString().replaceAll('Exception: ', '');
        isLoading = false;
      });
    }
  }

  Future<void> _showStatusDialog() async {
    final messageController = TextEditingController(text: statusMessage);
    String selectedAvailability = availability;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Status'),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: messageController,
                decoration: const InputDecoration(
                  labelText: 'Status Message',
                  hintText: 'What\'s on your mind?',
                  border: OutlineInputBorder(),
                ),
                maxLength: 150,
              ),
              const SizedBox(height: 16),
              const Text(
                'Availability',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildAvailabilityChip(
                    'available',
                    'Available',
                    Icons.check_circle,
                    const Color(0xFF059669),
                    selectedAvailability,
                    (value) => setState(() => selectedAvailability = value),
                  ),
                  _buildAvailabilityChip(
                    'busy',
                    'Busy',
                    Icons.work,
                    const Color(0xFFDC2626),
                    selectedAvailability,
                    (value) => setState(() => selectedAvailability = value),
                  ),
                  _buildAvailabilityChip(
                    'away',
                    'Away',
                    Icons.access_time,
                    const Color(0xFFEA580C),
                    selectedAvailability,
                    (value) => setState(() => selectedAvailability = value),
                  ),
                  _buildAvailabilityChip(
                    'do-not-disturb',
                    'DND',
                    Icons.do_not_disturb,
                    const Color(0xFF7C3AED),
                    selectedAvailability,
                    (value) => setState(() => selectedAvailability = value),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              // Clear status
              await ApiService.clearUserStatus();
              Navigator.pop(context, {
                'message': '',
                'availability': 'available',
              });
            },
            child: const Text('Clear'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, {
                'message': messageController.text,
                'availability': selectedAvailability,
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2463EB),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null) {
      try {
        final response = await ApiService.updateUserStatus(
          message: result['message'],
          availability: result['availability'],
        );

        if (response['success'] == true) {
          setState(() {
            statusMessage = result['message'];
            availability = result['availability'];
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Status updated successfully'),
                backgroundColor: Color(0xFF059669),
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Widget _buildAvailabilityChip(
    String value,
    String label,
    IconData icon,
    Color color,
    String selectedValue,
    ValueChanged<String> onSelected,
  ) {
    final isSelected = value == selectedValue;
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: isSelected ? Colors.white : color),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: (_) => onSelected(value),
      backgroundColor: Colors.white,
      selectedColor: color,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
        fontWeight: FontWeight.w500,
      ),
      side: BorderSide(color: color),
    );
  }

  String _getAvailabilityLabel() {
    switch (availability) {
      case 'busy':
        return 'Busy';
      case 'away':
        return 'Away';
      case 'do-not-disturb':
        return 'Do Not Disturb';
      case 'offline':
        return 'Offline';
      default:
        return 'Available';
    }
  }

  Color _getAvailabilityColor() {
    switch (availability) {
      case 'busy':
        return const Color(0xFFDC2626);
      case 'away':
        return const Color(0xFFEA580C);
      case 'do-not-disturb':
        return const Color(0xFF7C3AED);
      case 'offline':
        return const Color(0xFF64748B);
      default:
        return const Color(0xFF059669);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          // Header
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Colors.blue.shade100),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2463EB),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Profile',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E40AF),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: _loadProfileData,
                      color: const Color(0xFF2463EB),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Content
          Expanded(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF2463EB),
                    ),
                  )
                : errorMessage != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.error_outline,
                                color: Colors.red,
                                size: 48,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Error loading profile',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                errorMessage!,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton(
                                onPressed: _loadProfileData,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2463EB),
                                ),
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadProfileData,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              // Profile Info Card
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.blue.shade100),
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Avatar
                                        Container(
                                          width: 64,
                                          height: 64,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF2463EB),
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: const Color(0xFF2463EB),
                                              width: 2,
                                            ),
                                          ),
                                          child: Center(
                                            child: Text(
                                              userName.length >= 2
                                                  ? userName.substring(0, 2).toUpperCase()
                                                  : userName.isNotEmpty
                                                      ? userName.substring(0, 1).toUpperCase()
                                                      : '??',
                                              style: const TextStyle(
                                                fontSize: 24,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ),

                                        const SizedBox(width: 16),

                                        // User Info
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                userName,
                                                style: const TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF1E40AF),
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                userEmail,
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  color: Color(0xFF64748B),
                                                ),
                                              ),
                                              const SizedBox(height: 12),
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.circle,
                                                    size: 12,
                                                    color: _getAvailabilityColor(),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: _getAvailabilityColor().withOpacity(0.1),
                                                      border: Border.all(
                                                        color: _getAvailabilityColor().withOpacity(0.3),
                                                      ),
                                                      borderRadius: BorderRadius.circular(6),
                                                    ),
                                                    child: Text(
                                                      _getAvailabilityLabel(),
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        fontWeight: FontWeight.w600,
                                                        color: _getAvailabilityColor(),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              if (statusMessage.isNotEmpty) ...[
                                                const SizedBox(height: 8),
                                                Text(
                                                  statusMessage,
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                    color: Color(0xFF64748B),
                                                    fontStyle: FontStyle.italic,
                                                  ),
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 16),

                                    // Set Status Message Button
                                    InkWell(
                                      onTap: _showStatusDialog,
                                      borderRadius: BorderRadius.circular(8),
                                      child: Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.transparent,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: const [
                                            Icon(
                                              Icons.edit_outlined,
                                              size: 16,
                                              color: Color(0xFF2463EB),
                                            ),
                                            SizedBox(width: 8),
                                            Text(
                                              'Edit Status',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Color(0xFF2463EB),
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 16),

                              // Stats Cards
                              _buildStatCard(
                                  'Total Points', '$totalPoints P', const Color(0xFF2463EB)),
                              const SizedBox(height: 12),
                              _buildStatCard('Classes Enrolled', '$classesEnrolled',
                                  const Color(0xFF1E40AF)),
                              const SizedBox(height: 12),
                              _buildStatCard('Assessments Completed',
                                  '$assessmentsCompleted', const Color(0xFF1E40AF)),
                              const SizedBox(height: 12),
                              _buildStatCard('Average Score', '$averageScore%',
                                  const Color(0xFF059669)),

                              const SizedBox(height: 24),

                              // Logout Button
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: widget.onLogout,
                                  icon: const Icon(Icons.logout, size: 18),
                                  label: const Text('Logout'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFFDC2626),
                                    side: const BorderSide(color: Color(0xFFFECACA)),
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ).copyWith(
                                    backgroundColor: MaterialStateProperty.resolveWith(
                                      (states) {
                                        if (states.contains(MaterialState.pressed)) {
                                          return const Color(0xFFFEF2F2);
                                        }
                                        return Colors.transparent;
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color valueColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF64748B),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}