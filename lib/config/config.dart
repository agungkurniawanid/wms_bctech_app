// todo:✅ Clean Code checked
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/web.dart';

class Config {
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  String _baseUrl = '';
  String _apiKey = '';
  String _authKey = '';
  String _urlPdf = '';
  String _urlAbsn = '';

  Future<void> _loadConfigIfEmpty(
    String key,
    String propertyName,
    void Function(String) setter,
  ) async {
    if (propertyName.isEmpty) {
      try {
        final doc = await _firestore
            .collection('config')
            .doc(key)
            .get()
            .timeout(const Duration(seconds: 5));

        final value = doc.exists && doc.data() != null
            ? doc.get('value').toString()
            : '';
        setter(value);
      } catch (e) {
        setter('');
        Logger().e('Error loading config for $key: $e');
      }
    }
  }

  Future<String> url(String endpoint) async {
    await _loadConfigIfEmpty('baseUrl', _baseUrl, (value) => _baseUrl = value);
    if (_baseUrl.isEmpty) {
      throw Exception('Config for baseUrl not loaded properly.');
    }
    return _baseUrl + endpoint;
  }

  Future<String> urlkafka(String endpoint) async {
    await _loadConfigIfEmpty('urlkafka', _baseUrl, (value) => _baseUrl = value);
    if (_baseUrl.isEmpty) {
      throw Exception('Config for baseUrl not loaded properly.');
    }
    return _baseUrl + endpoint;
  }

  Future<String> urlsendemail(String endpoint) async {
    await _loadConfigIfEmpty(
      'urlsendemail',
      _baseUrl,
      (value) => _baseUrl = value,
    );
    if (_baseUrl.isEmpty) {
      throw Exception('Config for baseUrl not loaded properly.');
    }
    return _baseUrl + endpoint;
  }

  Future<String> apiKey() async {
    await _loadConfigIfEmpty('apiKey', _apiKey, (value) => _apiKey = value);
    if (_apiKey.isEmpty) {
      throw Exception('Config for apiKey not loaded properly.');
    }
    return _apiKey;
  }

  Future<String> authKey() async {
    await _loadConfigIfEmpty('authKey', _authKey, (value) => _authKey = value);
    if (_authKey.isEmpty) {
      throw Exception('Config for authKey not loaded properly.');
    }
    return _authKey;
  }

  Future<String> urlPdf() async {
    await _loadConfigIfEmpty('urlPdf', _urlPdf, (value) => _urlPdf = value);
    if (_urlPdf.isEmpty) {
      throw Exception('Config for urlPdf not loaded properly.');
    }
    return _urlPdf;
  }

  Future<String> urlAbsn() async {
    await _loadConfigIfEmpty('urlAbsn', _urlAbsn, (value) => _urlAbsn = value);
    if (_urlAbsn.isEmpty) {
      throw Exception('Config for urlAbsn not loaded properly.');
    }
    return _urlAbsn;
  }
}
