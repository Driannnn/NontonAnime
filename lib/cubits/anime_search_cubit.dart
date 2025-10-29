import 'package:bloc/bloc.dart';
import 'package:dio/dio.dart';
import '../models/anime_models.dart';
import 'anime_search_state.dart';

class AnimeSearchCubit extends Cubit<AnimeSearchState> {
  AnimeSearchCubit()
      : _dio = Dio(
          BaseOptions(baseUrl: 'https://www.sankavollerei.com'),
        ),
        super(AnimeSearchState.initial());

  final Dio _dio;

  Future<void> search(String rawKeyword) async {
    final keyword = rawKeyword.trim();
    if (keyword.isEmpty) {
      // kalau kosong jangan panggil API,
      // tapi tandai sudah pernah trigger biar UI bisa nunjukin kosong
      emit(
        state.copyWith(
          keyword: '',
          hasSearched: true,
          results: const [],
          error: null,
          loading: false,
        ),
      );
      return;
    }

    // emit loading
    emit(
      state.copyWith(
        loading: true,
        error: null,
        results: const [],
        hasSearched: true,
        keyword: keyword,
      ),
    );

    try {
      final res = await _dio.get('/anime/search/$keyword');
      final data = res.data;

      List rawList = [];

      // 1. search_results (sesuai contoh API kamu)
      if (data is Map && data['search_results'] is List) {
        rawList = data['search_results'];
      }
      // 2. fallback: data['data']
      else if (data is Map && data['data'] is List) {
        rawList = data['data'];
      }
      // 3. fallback: response langsung berupa List
      else if (data is List) {
        rawList = data;
      }

      final results = rawList
          .whereType<Map>()
          .map((e) => AnimeDisplay.fromMap(
                Map<String, dynamic>.from(e),
              ))
          .toList();

      emit(
        state.copyWith(
          loading: false,
          results: results,
          error: null,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          loading: false,
          error: e.toString(),
          results: const [],
        ),
      );
    }
  }
}
