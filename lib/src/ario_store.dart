import 'package:ario_store/ario_store.dart';
import 'package:arweave/arweave.dart';
import 'package:graphql/client.dart';

import 'arweave/arweave_service.dart';

class ArioStoreOptions {
  ArioStoreOptions({required this.gatewayUrl});

  final String gatewayUrl;
}

abstract class ArioStore {
  EntityMetadata getEntityMetadata(String entityId);
  Future<List<EntityMetadata>> getEntitiesMetadataFromCollection(
      CollectionSnapshot collection);
  Future<List<DriveMetadata>> getPublicDrivesFromOwner(String owner);
  Future<EntitySnapshot> getEntitySnapshot(EntityMetadata metadata);
  Future<CollectionSnapshot> getCollection(EntitySnapshot snapshot);
  Future<CollectionSnapshot> getRootFolder(DriveSnapshot driveSnapshot);

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
  Future<CollectionSnapshot<EntityMetadata>> getCollection(
      EntitySnapshot<EntityMetadata> snapshot) async {
    final metadatas = await arweaveService
        .getEntitiesMetadatasFromEntityMetadata(snapshot.metadata);

    final List<EntitySnapshot<EntityMetadata>> children = [];

    children.addAll(await Future.wait(
        metadatas.map((e) => arweaveService.getEntitySnapshot(e))));

    switch (snapshot.runtimeType) {
      case FolderSnapshot:
        return FolderCollection(
            name: snapshot.name,
            metadata: snapshot.metadata as FolderMetadata,
            children: children);
      case DriveSnapshot:
        return DriveCollection(
            name: snapshot.name,
            metadata: snapshot.metadata as DriveMetadata,
            children: children);
      default:
        throw Exception('${snapshot.runtimeType} is not supported');
    }
  }

  Future<CollectionSnapshot> getCollectionFromFolder(
      FolderSnapshot folderSnapshot) async {
    return getCollection(folderSnapshot);
  }

  @override
  Future<CollectionSnapshot> getRootFolder(DriveSnapshot driveSnapshot) async {
    final folderMetadata =
        await arweaveService.getFolderMetadata(driveSnapshot.rootFolderId);

    final rootFolderSnapshot =
        await arweaveService.getEntitySnapshot(folderMetadata);

    return getCollection(rootFolderSnapshot);
  }
}
