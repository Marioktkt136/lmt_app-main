import '../../models/lmt_models.dart';

/// Default seed timeline posts for L.M.T (empty for a clean team start).
class PostsSeed {
  PostsSeed._();

  /// Initial posts displayed in the Timeline Feed (empty for real usage).
  static List<PostModel> get initialPosts => const [];
}
