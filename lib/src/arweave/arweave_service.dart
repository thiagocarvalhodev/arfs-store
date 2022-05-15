import 'dart:convert';

import 'package:ario_store/src/entities/entity_metadata.dart';
import 'package:ario_store/src/entities/entity_snapshot.dart';
import 'package:arweave/arweave.dart';
import 'package:graphql/client.dart';

import 'graphql_queries.dart';

class ArweaveService {
  ArweaveService(this.client, this.arweave);

  final GraphQLClient client;
  final Arweave arweave;

  Future<EntitySnapshot> getEntitySnapshot(EntityMetadata metadata) async {
    final response = await arweave.api.get(metadata.transactionId);
    final json = jsonDecode(response.body);

    if (metadata is FolderMetadata) {
      return FolderSnapshot(name: json['name'], metadata: metadata);
    } else if (metadata is FileMetadata) {
      return FileSnapshot(name: json['name'], metadata: metadata);
    } else {
      return DriveSnapshot(
          rootFolderId: json['rootFolderId'],
          name: json['name'],
          metadata: metadata as DriveMetadata);
    }
  }

  Future<QueryResult> getTransactionsFromDrive(String driveId) {
    final QueryOptions options = QueryOptions(
      document: gql(queryEntity),
      variables: <String, dynamic>{'driveId': driveId, 'lastBlockHeight': 0},
    );

    return client.query(options);
  }

  /// Get the a list of entity metadatas from colleciton
  // TODO: Pass filters
  Future<List<EntityMetadata>> getEntitiesMetadatasFromCollection(
      CollectionSnapshot collection) async {
    final QueryOptions options = QueryOptions(
      document: gql(queryEntity),
      variables: <String, dynamic>{
        'driveId': collection.metadata.id,
        'lastBlockHeight': 0,
        'tag': getCollectionTag(collection)
      },
    );

    final query = await client.query(options);

    final list = query.data!['transactions']['edges'] as List;

    return list.map((e) {
      final tags = parseTagsToMap(e['node']['tags']);

      if (tags['Entity-Type'] == EntityType.folder.name) {
        return FolderMetadata(
            transactionId: e['node']['id'],
            id: tags['Folder-Id'],
            arFS: tags['ArFS'],
            contentType: tags["Content-Type"],
            unixTime: DateTime.fromMicrosecondsSinceEpoch(
                int.parse(tags["Unix-Time"])),
            parentFolderId: tags['Parent-Folder-Id'],
            driveId: tags['Drive-Id']);
      } else if (tags['Entity-Type'] == EntityType.file.name) {
        return FileMetadata(
            transactionId: e['node']['id'],
            id: tags['File-Id'],
            arFS: tags['ArFS'],
            contentType: tags["Content-Type"],
            unixTime: DateTime.fromMicrosecondsSinceEpoch(
                int.parse(tags["Unix-Time"])),
            parentFolderId: tags['Parent-Folder-Id'],
            driveId: tags['Drive-Id']);
      } else {
        throw Exception('This ${tags['Entity-Type']} is not supported');
      }
    }).toList();
  }

  Future<List<DriveMetadata>> getAllPublicDrivesFromOwner(String owner) async {
    final QueryOptions options = QueryOptions(
      document: gql(getPublicDrives),
      variables: <String, dynamic>{'owner': owner},
    );

    final query = await client.query(options);

    final list = query.data!['transactions']['edges'] as List;

    return list.map((e) {
      final tags = parseTagsToMap(e['node']['tags']);

      return DriveMetadata(
        transactionId: e['node']['id'],
        id: tags['Drive-Id'],
        arFS: tags['ArFS'],
        contentType: tags["Content-Type"],
        unixTime:
            DateTime.fromMicrosecondsSinceEpoch(int.parse(tags["Unix-Time"])),
      );
    }).toList();
  }

  Future<List<EntityMetadata>> getFolderChildren(String id) async {
    final QueryOptions options = QueryOptions(
      document: gql(getRootFolderQuery),
      variables: <String, dynamic>{'folderId': id},
    );

    final query = await client.query(options);

    final list = query.data!['transactions']['edges'] as List;

    return list.map((e) {
      final tags = parseTagsToMap(e['node']['tags']);
      if (tags['Entity-Type'] == EntityType.folder.name) {
        return FolderMetadata(
            transactionId: e['node']['id'],
            id: tags['Folder-Id'],
            arFS: tags['ArFS'],
            contentType: tags["Content-Type"],
            unixTime: DateTime.fromMicrosecondsSinceEpoch(
                int.parse(tags["Unix-Time"])),
            parentFolderId: tags['Parent-Folder-Id'],
            driveId: tags['Drive-Id']);
      } else if (tags['Entity-Type'] == EntityType.file.name) {
        return FileMetadata(
            transactionId: e['node']['id'],
            id: tags['File-Id'],
            arFS: tags['ArFS'],
            contentType: tags["Content-Type"],
            unixTime: DateTime.fromMicrosecondsSinceEpoch(
                int.parse(tags["Unix-Time"])),
            parentFolderId: tags['Parent-Folder-Id'],
            driveId: tags['Drive-Id']);
      } else {
        throw Exception('This ${tags['Entity-Type']} is not supported');
      }
    }).toList();
  }

  Future<FolderMetadata> getFolderMetadata(String folderId) async {
    final QueryOptions options = QueryOptions(
      document: gql(queryFolder),
      variables: <String, dynamic>{'folderId': folderId},
    );

    final query = await client.query(options);

    final list = query.data!['transactions']['edges'] as List;
    final folderMetadata = list.first;
    final tags = parseTagsToMap(folderMetadata['node']['tags']);

    return FolderMetadata(
        transactionId: folderMetadata['node']['id'],
        id: tags['Folder-Id'],
        arFS: tags['ArFS'],
        contentType: tags["Content-Type"],
        unixTime:
            DateTime.fromMicrosecondsSinceEpoch(int.parse(tags["Unix-Time"])),
        parentFolderId: tags['Parent-Folder-Id'],
        driveId: tags['Drive-Id']);
  }
}

String getCollectionTag(CollectionSnapshot c) {
  switch (c.runtimeType) {
    case FolderSnapshot:
      return 'Parent-Folder-Id';
    case DriveSnapshot:
      return 'Drive-Id';
    default:
      return throw Exception(
          'Collection ${c.runtimeType} is not supported for queires');
  }
}

String? getTag(String tagName, List<dynamic> tags) =>
    tags.firstWhere((t) => t['name'] == tagName, orElse: () => null)?['value'];

Map<String, dynamic> parseTagsToMap(List tags) {
  final map = <String, dynamic>{};
  for (var e in tags) {
    map.putIfAbsent(e['name'], () => e['value']);
  }
  return map;
}
