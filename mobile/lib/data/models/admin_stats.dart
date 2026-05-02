class AdminStats {
  final int approved;
  final int pending;
  final int suspended;
  final int rejected;
  final int admins;
  final int newLast30Days;

  final int newsCount;
  final int contractsCount;
  final int upcomingEventsCount;

  final int openSuggestions;
  final int totalSuggestions;

  final List<DistEntry> byGovernorate;
  final List<DistEntry> byRank;

  AdminStats({
    required this.approved,
    required this.pending,
    required this.suspended,
    required this.rejected,
    required this.admins,
    required this.newLast30Days,
    required this.newsCount,
    required this.contractsCount,
    required this.upcomingEventsCount,
    required this.openSuggestions,
    required this.totalSuggestions,
    required this.byGovernorate,
    required this.byRank,
  });

  factory AdminStats.fromJson(Map<String, dynamic> json) {
    final m = json['members'] as Map<String, dynamic>;
    final c = json['content'] as Map<String, dynamic>;
    final s = json['suggestions'] as Map<String, dynamic>;
    final d = json['distribution'] as Map<String, dynamic>;

    List<DistEntry> parseList(String key) {
      return (d[key] as List)
          .map((e) => DistEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return AdminStats(
      approved: m['approved'] as int,
      pending: m['pending'] as int,
      suspended: m['suspended'] as int,
      rejected: m['rejected'] as int,
      admins: m['admins'] as int,
      newLast30Days: m['newLast30Days'] as int,
      newsCount: c['news'] as int,
      contractsCount: c['contracts'] as int,
      upcomingEventsCount: c['upcomingEvents'] as int,
      openSuggestions: s['open'] as int,
      totalSuggestions: s['total'] as int,
      byGovernorate: parseList('byGovernorate'),
      byRank: parseList('byRank'),
    );
  }
}

class DistEntry {
  final String name;
  final int count;
  DistEntry({required this.name, required this.count});
  factory DistEntry.fromJson(Map<String, dynamic> json) => DistEntry(
        name: json['name'] as String,
        count: json['count'] as int,
      );
}
