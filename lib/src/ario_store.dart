import 'package:arweave/arweave.dart';
import 'package:graphql/client.dart';

import 'arweave/arweave_service.dart';
import 'entities/entity_metadata.dart';
import 'entities/entity_snapshot.dart';

class ArioStoreOptions {
  ArioStoreOptions({required this.gatewayUrl});

  final String gatewayUrl;
}

abstract class ArioStore {
  EntityMetadata getEntityMetadata(String entityId);
  Future<List<EntityMetadata>> getEntitiesMetadataFromCollection(
      CollectionSnapshot collection);
  Future<List<DriveMetadata>> getPublicDrivesFromOwner(String owner);
  Future<CollectionSnapshot> getCollectionFromEntityMetadata(
      EntityMetadata metadata);
  Future<EntitySnapshot> getEntitySnapshot(EntityMetadata metadata);

  factory ArioStore(ArioStoreOptions options) => _ArioStore(ArweaveService(
      GraphQLClient(
          link: HttpLink('${options.gatewayUrl}/graphql'),
          cache: GraphQLCache()),
      Arweave(gatewayUrl: Uri.parse(options.gatewayUrl))));
}

class _ArioStore implements ArioStore {
  _ArioStore(this.arweaveService);

  final ArweaveService arweaveService;

  @override
  EntityMetadata getEntityMetadata(String entityId) {
    throw UnimplementedError();
  }

  @override
  Future<EntitySnapshot> getEntitySnapshot(EntityMetadata metadata) async {
    return arweaveService.getEntitySnapshot(metadata);
  }

  // TODO(thiagocarvalho): Filter by type.
  @override
  Future<List<EntityMetadata>> getEntitiesMetadataFromCollection(
      CollectionSnapshot collection) async {
    final collectionMetadatas =
        await arweaveService.getEntitiesMetadatasFromCollection(collection);

    return collectionMetadatas;
  }

  @override
  Future<List<DriveMetadata>> getPublicDrivesFromOwner(String owner) {
    return arweaveService.getAllPublicDrivesFromOwner(owner);
  }

  @override
  Future<CollectionSnapshot> getRootFolder(DriveSnapshot driveSnapshot) async {
    final folderMetadata =
        await arweaveService.getFolderMetadata(driveSnapshot.rootFolderId);

    final folderSnapshot =
        await arweaveService.getEntitySnapshot(folderMetadata);

    final rootFolderChildren =
        await arweaveService.getFolderChildren(driveSnapshot.rootFolderId);

    final List<EntitySnapshot<EntityMetadata>> children = [];

    children.addAll(await Future.wait(rootFolderChildren.map((e) async {
      return arweaveService.getEntitySnapshot(e);
    })));

    CollectionSnapshot collection = FolderCollection(
        name: folderSnapshot.name,
        metadata: folderSnapshot.metadata as FolderMetadata,
        children: children);

    return collection;
  }

  Future<CollectionSnapshot> getCollectionFromFolder(
      FolderSnapshot folderSnapshot) async {
    final folderChildrenMetadatas =
        await arweaveService.getFolderChildren(folderSnapshot.metadata.id);

    final List<EntitySnapshot<EntityMetadata>> children = [];

    children.addAll(await Future.wait(folderChildrenMetadatas
        .map((e) => arweaveService.getEntitySnapshot(e))));

    return FolderCollection(
        name: folderSnapshot.name,
        metadata: folderSnapshot.metadata,
        children: children);
  }

  @override
  Future<CollectionSnapshot<EntityMetadata>> getCollectionFromEntityMetadata(
      EntityMetadata metadata) {
    // TODO: implement getCollectionFromEntityMetadata
    throw UnimplementedError();
  }
}
