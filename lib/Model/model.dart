class Persona {
  final int id;
  final String name;
  final String desc;
  final String? imageUrl;

  Persona({
    required this.id,
    required this.name,
    required this.desc,
    this.imageUrl,
  });

  factory Persona.fromJson(Map<String, dynamic> json) {
    return Persona(
      id: json['id'],
      name: json['name'],
      desc: json['desc'],
      imageUrl: json['image_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'desc': desc,
      'image_url': imageUrl,
    };
  }
}

class Message {
  final int id;
  final int senderId;
  final int receiverId;
  final String text;
  final DateTime timestamp;
  final String? imageFileName;
  final bool isUser;

  Message({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.text,
    required this.timestamp,
    this.imageFileName,
    this.isUser = false,
  });

  factory Message.fromJson(Map<String, dynamic> json, int currentUserId) {
    return Message(
      id: json['id'],
      senderId: json['sender_id'],
      receiverId: json['receiver_id'],
      text: json['text'],
      timestamp: json['timestamp'] != null 
          ? DateTime.parse(json['timestamp']) 
          : DateTime.now(),
      imageFileName: json['image_object_name'],
      isUser: json['sender_id'] == currentUserId,
    );
  }

  String get timeStampString {
    return "${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}";
  }
}

class Challenge {
  final String id;
  final String title;
  final String? subtitle;
  final String? description;
  final String? shortDescription;
  final List<String>? categories;
  final List<int>? suggestedPersonas;
  final String? difficulty;
  final String? imageUrl;
  final int? selectedPersonaId;
  final ChallengeContext? context;

  Challenge({
    required this.id,
    required this.title,
    this.subtitle,
    this.description,
    this.shortDescription,
    this.categories,
    this.suggestedPersonas,
    this.difficulty,
    this.imageUrl,
    this.selectedPersonaId,
    this.context,
  });

  factory Challenge.fromJson(Map<String, dynamic> json) {
    return Challenge(
      id: json['id'].toString(),
      title: json['title'] ?? '',
      subtitle: json['subtitle'],
      description: json['description'],
      shortDescription: json['short_description'],
      categories: json['categories'] != null ? List<String>.from(json['categories']) : null,
      suggestedPersonas: json['suggested_personas'] != null ? List<int>.from(json['suggested_personas']) : null,
      difficulty: json['difficulty'],
      imageUrl: json['image_url'],
      selectedPersonaId: json['selected_persona_id'] != null ? json['selected_persona_id'] as int : null,
      context: json['context'] != null ? ChallengeContext.fromJson(json['context']) : null,
    );
  }
}

class ChallengeContext {
  final int id;
  final String challengeId;
  final String setting;
  final String goal;
  final String stakes;
  final String platform;

  ChallengeContext({
    required this.id,
    required this.challengeId,
    required this.setting,
    required this.goal,
    required this.stakes,
    required this.platform,
  });

  factory ChallengeContext.fromJson(Map<String, dynamic> json) {
    return ChallengeContext(
      id: json['id'],
      challengeId: json['challenge_id'] ?? '',
      setting: json['setting'] ?? '',
      goal: json['goal'] ?? '',
      stakes: json['stakes'] ?? '',
      platform: json['platform'] ?? '',
    );
  }
}
