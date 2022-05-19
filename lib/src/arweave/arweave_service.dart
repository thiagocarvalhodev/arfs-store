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
      return FileSnapshot(
          dataContentType: json['dataContentType'],
          dataTxId: json['dataTxId'],
          lastModifiedDate:
              DateTime.fromMillisecondsSinceEpoch(json['lastModifiedDate']),
          size: json['size'],
          name: json['name'],
          metadata: metadata);
    } else {
      return DriveSnapshot(
          rootFolderId: json['rootFolderId'],
          name: json['name'],
          metadata: metadata as DriveMetadata);
    }
  }

  Future<List<EntityMetadata>> getEntitiesMetadatasFromEntityMetadata(
      EntityMetadata metadata) async {
    final List<EntityMetadata> metadatas = [];

    String? cursor;

    while (true) {
      // Get a page of 100 transactions
      final QueryOptions options = QueryOptions(
        document: gql(queryEntityList),
        variables: <String, dynamic>{
          'driveId': metadata.id,
          'lastBlockHeight': 0,
          'after': cursor,
          'tag': getEntityTypeTagFromEntityType(metadata.entityType)
        },
      );

      final query = await client.query(options);

      final list = query.data!['transactions']['edges'] as List;

      if (list.isEmpty) {
        break;
      }

      // TODO(@thiagocarvalhodev) Implement an Adapter
      metadatas.addAll(list.map((e) {
        final tags = parseTagsToMap(e['node']['tags']);

        if (tags['Entity-Type'] == EntityType.folder.name) {
          return FolderMetadata(
              entityType: entityTypeFromTag(tags['Entity-Type']),
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
              entityType: entityTypeFromTag(tags['Entity-Type']),
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
      }).toList());
      cursor = list.last['cursor'];

      if (!query.data!['transactions']['pageInfo']['hasNextPage']) {
        break;
      }
    }
    return metadatas;
  }

  /// Get the a list of entity metadatas from colleciton
  // TODO: Pass filters
  Future<List<EntityMetadata>> getEntitiesMetadatasFromCollection(
      CollectionSnapshot collection) async {
    final QueryOptions options = QueryOptions(
      document: gql(queryEntityList),
      variables: <String, dynamic>{
        'driveId': collection.metadata.id,
        'lastBlockHeight': 0,
        'tag': getEntityTypeTagFromCollection(collection)
      },
    );

    final query = await client.query(options);

    final list = query.data!['transactions']['edges'] as List;

    // TODO(@thiagocarvalhodev) Implement an Adapter
    return list.map((e) {
      final tags = parseTagsToMap(e['node']['tags']);

      if (tags['Entity-Type'] == EntityType.folder.name) {
        return FolderMetadata(
            entityType: entityTypeFromTag(tags['Entity-Type']),
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
            entityType: entityTypeFromTag(tags['Entity-Type']),
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
        entityType: entityTypeFromTag(tags['Entity-Type']),
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
            entityType: entityTypeFromTag(tags['Entity-Type']),
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
            entityType: entityTypeFromTag(tags['Entity-Type']),
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
        entityType: entityTypeFromTag(tags['Entity-Type']),
        contentType: tags["Content-Type"],
        unixTime:
            DateTime.fromMicrosecondsSinceEpoch(int.parse(tags["Unix-Time"])),
        parentFolderId: tags['Parent-Folder-Id'],
        driveId: tags['Drive-Id']);
  }
}

String getEntityTypeTagFromCollection(CollectionSnapshot c) {
  switch (c.runtimeType) {
    case FolderSnapshot:
      return 'Parent-Folder-Id';
    case DriveSnapshot:
      return 'Drive-Id';
    default:
      return throw Exception(
          'Collection ${c.runtimeType} is not supported for queries');
  }
}

String getEntityTypeTagFromEntityType(EntityType? t) {
  assert(t != null);

  switch (t) {
    case EntityType.folder:
      return 'Parent-Folder-Id';
    case EntityType.drive:
      return 'Drive-Id';
    default:
      return throw Exception(
          'Collection ${t!.name} is not supported for queries');
  }
}

EntityType entityTypeFromTag(String tag) {
  switch (tag) {
    case 'folder':
      return EntityType.folder;
    case 'drive':
      return EntityType.drive;
    case 'file':
      return EntityType.folder;
    case 'manifest':
      return EntityType.manifest;
    default:
      throw Exception('$tag is not a EntityType');
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
