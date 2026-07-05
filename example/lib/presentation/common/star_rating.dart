import 'package:flutter/material.dart';

/// A row of filled/empty stars for a 0..5 [rating].
class StarRating extends StatelessWidget {
  const StarRating({super.key, required this.rating, this.size = 16});

  final double rating;
  final double size;

  @override
  Widget build(BuildContext context) {
    final rounded = rating.round();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          Icon(
            i <= rounded ? Icons.star : Icons.star_border,
            size: size,
            color: Colors.amber,
          ),
      ],
    );
  }
}
