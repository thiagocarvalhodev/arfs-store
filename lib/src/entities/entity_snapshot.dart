import 'package:ario_store/src/entities/entity_metadata.dart';

import 'entity.dart';

abstract class EntitySnapshot<T extends EntityMetadata> extends Entity {
  EntitySnapshot({required String name, required this.metadata}) : super(name);
  T metadata;
}

class FileSnapshot extends EntitySnapshot<FileMetadata> {
  FileSnapshot({required String name, required FileMetadata metadata})
      : super(name: name, metadata: metadata);
}

class FolderSnapshot extends EntitySnapshot<FolderMetadata> {
  FolderSnapshot({required String name, required FolderMetadata metadata})
      : super(name: name, metadata: metadata);
}

class DriveSnapshot extends EntitySnapshot<DriveMetadata> {
  DriveSnapshot(
      {required String name,
      required DriveMetadata metadata,
      required this.rootFolderId})
      : super(name: name, metadata: metadata);
  final String rootFolderId;
}

abstract class CollectionSnapshot<T extends EntityMetadata>
    extends EntitySnapshot {
  CollectionSnapshot(
      {required String name, required T metadata, required this.children})
      : super(name: name, metadata: metadata);
  List<EntitySnapshot<EntityMetadata>> children;
}

class FolderCollection extends CollectionSnapshot<FolderMetadata> {
  FolderCollection(
      {required String name,
      required FolderMetadata metadata,
      required List<EntitySnapshot<EntityMetadata>> children})
      : super(name: name, metadata: metadata, children: children);
}

class DriveCollection extends CollectionSnapshot<DriveMetadata> {
  DriveCollection(
      {required String name,
      required DriveMetadata metadata,
      required List<EntitySnapshot<EntityMetadata>> children})
      : super(name: name, metadata: metadata, children: children);
}
