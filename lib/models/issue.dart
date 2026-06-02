class Issue {
  final String id;
  final String reporterUid;
  final String reporterName;
  final String title;
  final String description;
  final String category;
  final String urgency; // 'Low' | 'Medium' | 'High'
  final String? imageUrl;
  final double? latitude;
  final double? longitude;
  final String? address;
  final String status; // 'reported' | 'assigned' | 'in-progress' | 'resolved'
  final String? assignedTo;
  final DateTime createdAt;
  final DateTime updatedAt;

  Issue({
    required this.id,
    required this.reporterUid,
    required this.reporterName,
    required this.title,
    required this.description,
    required this.category,
    required this.urgency,
    this.imageUrl,
    this.latitude,
    this.longitude,
    this.address,
    required this.status,
    this.assignedTo,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Issue.fromMap(Map<String, dynamic> map, String id) {
    return Issue(
      id: id,
      reporterUid: map['reporterUid'] ?? '',
      reporterName: map['reporterName'] ?? 'Anonymous',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? 'Other',
      urgency: map['urgency'] ?? 'Medium',
      imageUrl: map['imageUrl'],
      latitude: map['location'] != null ? (map['location']['lat'] as num?)?.toDouble() : null,
      longitude: map['location'] != null ? (map['location']['lng'] as num?)?.toDouble() : null,
      address: map['location'] != null ? map['location']['address'] : null,
      status: map['status'] ?? 'reported',
      assignedTo: map['assignedTo'],
      createdAt: map['createdAt'] != null 
          ? (map['createdAt'] is String ? DateTime.parse(map['createdAt']) : map['createdAt'].toDate())
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] is String ? DateTime.parse(map['updatedAt']) : map['updatedAt'].toDate())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'reporterUid': reporterUid,
      'reporterName': reporterName,
      'title': title,
      'description': description,
      'category': category,
      'urgency': urgency,
      if (imageUrl != null) 'imageUrl': imageUrl,
      'location': {
        'lat': latitude,
        'lng': longitude,
        'address': address,
      },
      'status': status,
      if (assignedTo != null) 'assignedTo': assignedTo,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
