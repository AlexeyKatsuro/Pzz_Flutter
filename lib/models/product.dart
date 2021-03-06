import 'package:flutter/material.dart';
import 'package:pzz/models/pizza.dart';

@immutable
class Product {
  const Product({
    required this.id,
    required this.type,
    required this.price,
    required this.title,
    this.size,
  });

  final int id;
  final ProductSize? size;
  final ProductType type;
  final String title;
  final num price;
}
