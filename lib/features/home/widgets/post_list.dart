import 'package:flutter/material.dart';
import 'package:lmt/features/home/widgets/poll_post_card.dart';
import 'package:lmt/features/home/widgets/text_post_card.dart';

class PostsList extends StatelessWidget {
  const PostsList({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        Padding(padding: const EdgeInsets.symmetric(vertical: 2.0), child: PollPostCard()),
        Padding(padding: const EdgeInsets.symmetric(vertical: 2.0), child: TextPostCard()),
        Padding(padding: const EdgeInsets.symmetric(vertical: 2.0), child: TextPostCard()),
        Padding(padding: const EdgeInsets.symmetric(vertical: 2.0), child: PollPostCard()),
      ],
    );
  }
}
