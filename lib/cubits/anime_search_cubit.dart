import 'package:bloc/bloc.dart';
import '../core/api_client.dart';
import '../models/anime_models.dart';
import 'anime_search_state.dart';

class AnimeSearchCubit extends Cubit<AnimeSearchState> {
  AnimeSearchCubit() : super(AnimeSearchState.initial());

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
      final animeList = await fetchSearchAnime(keyword);

      final results = animeList
          .map((e) => AnimeDisplay.fromMap(e))
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
