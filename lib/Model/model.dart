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
