import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';

class Role {
  final List<String>? stocktake;
  final List<String>? inmodel;
  final List<String>? outmodel;
  final String? updated;
  final String? updatedby;

  Role({
    this.stocktake,
    this.inmodel,
    this.outmodel,
    this.updated,
    this.updatedby,
  });

  factory Role.empty() {
    return Role(
      stocktake: [],
      inmodel: [],
      outmodel: [],
      updated: '',
      updatedby: '',
    );
  }

  factory Role.fromJson(Map<String, dynamic> data) {
    return Role(
      stocktake:
          (data['stocktake'] as List?)?.map((e) => e.toString()).toList() ?? [],
      inmodel:
          (data['inmodel'] as List?)?.map((e) => e.toString()).toList() ?? [],
      outmodel:
          (data['outmodel'] as List?)?.map((e) => e.toString()).toList() ?? [],
      updated: data['updated']?.toString() ?? '',
      updatedby: data['updatedby']?.toString() ?? '',
    );
  }

  factory Role.fromDocumentSnapshot(DocumentSnapshot documentSnapshot) {
    try {
      final data = documentSnapshot.data() as Map<String, dynamic>? ?? {};
      return Role(
        stocktake: List<String>.from(data['stocktake'] ?? []),
        inmodel: List<String>.from(data['inmodel'] ?? []),
        outmodel: List<String>.from(data['outmodel'] ?? []),
        updated: data['updated'] ?? '',
        updatedby: data['updatedby'] ?? '',
      );
    } catch (e) {
      Logger().e('Error parsing Role from Firestore: $e');
      return Role.empty(); // Use empty constructor here
    }
  }

  Map<String, dynamic> toJsonUser() => {
    "stocktake": stocktake ?? [],
    "inmodel": inmodel ?? [],
    "outmodel": outmodel ?? [],
    "updatedby": updatedby ?? '',
    "updated": updated ?? '',
  };

  bool get isEmpty {
    return (stocktake?.isEmpty ?? true) &&
        (inmodel?.isEmpty ?? true) &&
        (outmodel?.isEmpty ?? true);
  }

  @override
  String toString() {
    return 'Role(stocktake: $stocktake, inmodel: $inmodel, outmodel: $outmodel, updated: $updated, updatedby: $updatedby)';
  }
}

String toJsonUser(Role data) => json.encode(data.toJsonUser());
