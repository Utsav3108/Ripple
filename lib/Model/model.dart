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
      id: json['id'] is int 
          ? json['id'] as int 
          : (int.tryParse(json['id']?.toString() ?? '') ?? 0),
      name: json['name']?.toString() ?? '',
      desc: json['desc']?.toString() ?? '',
      imageUrl: json['image_url']?.toString(),
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
    final parsedId = json['id'] is int 
        ? json['id'] as int 
        : (int.tryParse(json['id']?.toString() ?? '') ?? 0);
    final parsedSenderId = json['sender_id'] is int 
        ? json['sender_id'] as int 
        : (int.tryParse(json['sender_id']?.toString() ?? '') ?? 0);
    final parsedReceiverId = json['receiver_id'] is int 
        ? json['receiver_id'] as int 
        : (int.tryParse(json['receiver_id']?.toString() ?? '') ?? 0);
    return Message(
      id: parsedId,
      senderId: parsedSenderId,
      receiverId: parsedReceiverId,
      text: json['text']?.toString() ?? '',
      timestamp: json['timestamp'] != null 
          ? DateTime.parse(json['timestamp']) 
          : DateTime.now(),
      imageFileName: json['image_object_name']?.toString(),
      isUser: parsedSenderId == currentUserId,
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
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      subtitle: json['subtitle']?.toString(),
      description: json['description']?.toString(),
      shortDescription: json['short_description']?.toString(),
      categories: json['categories'] != null 
          ? List<String>.from((json['categories'] as List).map((e) => e.toString())) 
          : null,
      suggestedPersonas: json['suggested_personas'] != null 
          ? List<int>.from((json['suggested_personas'] as List)
              .map((e) => e is int ? e : (int.tryParse(e.toString()) ?? 0))
              .where((e) => e != 0)) 
          : null,
      difficulty: json['difficulty']?.toString(),
      imageUrl: json['image_url']?.toString(),
      selectedPersonaId: json['selected_persona_id'] is int 
          ? json['selected_persona_id'] as int 
          : (json['selected_persona_id'] != null 
              ? int.tryParse(json['selected_persona_id'].toString()) 
              : null),
      context: json['context'] is Map 
          ? ChallengeContext.fromJson(Map<String, dynamic>.from(json['context'] as Map)) 
          : null,
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

class ChallengeAttempt {
  final String id;
  final String challengeId;
  final int userId;
  final int personaId;
  final bool won;
  final int timeTakenSeconds;
  final int attemptNumber;
  final DateTime createdAt;
  final int? challengeSessionId;

  ChallengeAttempt({
    required this.id,
    required this.challengeId,
    required this.userId,
    required this.personaId,
    required this.won,
    required this.timeTakenSeconds,
    required this.attemptNumber,
    required this.createdAt,
    this.challengeSessionId,
  });

  factory ChallengeAttempt.fromJson(Map<String, dynamic> json) {
    final rawSessionId = json['challenge_session_id'] ?? json['id'];
    final parsedSessionId = rawSessionId is int 
        ? rawSessionId 
        : (rawSessionId != null ? int.tryParse(rawSessionId.toString()) : null);
    return ChallengeAttempt(
      id: json['id']?.toString() ?? '',
      challengeId: json['challenge_id']?.toString() ?? '',
      userId: json['user_id'] is int ? json['user_id'] as int : 0,
      personaId: json['persona_id'] is int ? json['persona_id'] as int : 0,
      won: json['won'] is bool ? json['won'] as bool : false,
      timeTakenSeconds: json['time_taken_seconds'] is int 
          ? json['time_taken_seconds'] as int 
          : (json['time_taken_seconds'] is double 
              ? (json['time_taken_seconds'] as double).toInt() 
              : 0),
      attemptNumber: json['attempt_number'] is int ? json['attempt_number'] as int : 0,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
      challengeSessionId: parsedSessionId,
    );
  }
}
