class Item {
  final String iid;
  final String name;
  final List<String> description;
  final String photoUrl;
  final String qtyTotal;
  final String qtyAvailable;
  final String isActive;
  final bool isWishlisted;

  Item({
    this.iid = '',
    required this.name,
    required this.description,
    required this.photoUrl,
    required this.qtyTotal,
    required this.qtyAvailable,
    required this.isActive,
    this.isWishlisted = false,
  });

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      iid: json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description'] != null
          ? List<String>.from(json['description'].map((e) => e.toString()))
          : <String>[],
      photoUrl: json['photoUrl']?.toString() ?? '',
      qtyTotal: json['qtyTotal']?.toString() ?? '',
      qtyAvailable: json['qtyAvailable']?.toString() ?? '',
      isActive: json['isActive']?.toString() ?? '',
      isWishlisted: json['isWishlisted'] == true,
    );
  }

  Item copyWith({
    String? iid,
    String? name,
    List<String>? description,
    String? photoUrl,
    String? qtyTotal,
    String? qtyAvailable,
    String? isActive,
    bool? isWishlisted,
  }) {
    return Item(
      iid: iid ?? this.iid,
      name: name ?? this.name,
      description: description ?? this.description,
      photoUrl: photoUrl ?? this.photoUrl,
      qtyTotal: qtyTotal ?? this.qtyTotal,
      qtyAvailable: qtyAvailable ?? this.qtyAvailable,
      isActive: isActive ?? this.isActive,
      isWishlisted: isWishlisted ?? this.isWishlisted,
    );
  }
}
