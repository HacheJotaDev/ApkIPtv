class Channel {
  final String id;
  final String name;
  final String categoryId;
  final String streamUrl;
  final String logo;
  final String epgChannelId;
  final String streamType;

  Channel({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.streamUrl,
    this.logo = '',
    this.epgChannelId = '',
    this.streamType = 'live',
  });

  factory Channel.fromXtream(Map<String, dynamic> json, String serverUrl, String username, String password) {
    return Channel(
      id: json['stream_id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Sin nombre',
      categoryId: json['category_id']?.toString() ?? '',
      streamUrl: '$serverUrl/live/$username/$password/${json['stream_id']}.m3u8',
      logo: json['stream_icon']?.toString() ?? '',
      epgChannelId: json['epg_channel_id']?.toString() ?? '',
      streamType: 'live',
    );
  }

  factory Channel.fromM3u(Map<String, dynamic> data) {
    return Channel(
      id: data['id']?.toString() ?? '',
      name: data['name']?.toString() ?? 'Sin nombre',
      categoryId: data['group']?.toString() ?? '',
      streamUrl: data['url']?.toString() ?? '',
      logo: data['logo']?.toString() ?? '',
      streamType: 'live',
    );
  }
}
