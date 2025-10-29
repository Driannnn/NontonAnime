import 'package:equatable/equatable.dart';
import '../models/anime_models.dart';

class AnimeSearchState extends Equatable {
  final bool loading;
  final String? error;
  final List<AnimeDisplay> results;
  final bool hasSearched;
  final String keyword;

  const AnimeSearchState({
    required this.loading,
    required this.error,
    required this.results,
    required this.hasSearched,
    required this.keyword,
  });

  factory AnimeSearchState.initial() => const AnimeSearchState(
        loading: false,
        error: null,
        results: <AnimeDisplay>[],
        hasSearched: false,
        keyword: '',
      );

  AnimeSearchState copyWith({
    bool? loading,
    String? error,
    List<AnimeDisplay>? results,
    bool? hasSearched,
    String? keyword,
  }) {
    return AnimeSearchState(
      loading: loading ?? this.loading,
      error: error,
      results: results ?? this.results,
      hasSearched: hasSearched ?? this.hasSearched,
      keyword: keyword ?? this.keyword,
    );
  }

  @override
  List<Object?> get props => [
        loading,
        error,
        results,
        hasSearched,
        keyword,
      ];
}
