import 'package:dio/dio.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/dio_client.dart';
import '../models/contract.dart';

class ContractsRepository {
  final DioClient client;
  ContractsRepository(this.client);

  Future<List<Contract>> list() async {
    final res = await client.dio.get(ApiConstants.contracts);
    return (res.data['items'] as List)
        .map((e) => Contract.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Contract> create({
    required String title,
    String? description,
    String? category,
    required String filePath,
  }) async {
    final form = FormData.fromMap({
      'title': title,
      if (description != null) 'description': description,
      if (category != null) 'category': category,
      'file': await MultipartFile.fromFile(filePath),
    });
    final res = await client.dio.post(ApiConstants.contracts, data: form);
    return Contract.fromJson(res.data['contract'] as Map<String, dynamic>);
  }

  Future<void> remove(String id) async {
    await client.dio.delete('${ApiConstants.contracts}/$id');
  }
}
