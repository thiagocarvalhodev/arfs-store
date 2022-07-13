import 'package:ario_store/ario_store.dart';
import 'package:ario_store/entities.dart';

abstract class EntitySnapshot<T extends EntityMetadata> extends Entity {
  EntitySnapshot({required String name, required this.metadata}) : super(name);
  T metadata;
}

class FileSnapshot extends EntitySnapshot<FileMetadata> {
  FileSnapshot(
      {required String name,
      required FileMetadata metadata,
      required this.dataContentType,
      required this.dataTxId,
      required this.lastModifiedDate,
      required this.size})
      : super(name: name, metadata: metadata);

  int size;
  DateTime lastModifiedDate;
  String dataTxId;
  String dataContentType;
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

class CollectionRevision<T extends EntitySnapshot> extends CollectionSnapshot {
  CollectionRevision(
      {required this.itself,
      required List<EntitySnapshot<EntityMetadata>> children})
      : super(name: itself.name, metadata: itself.metadata, children: children);

  EntitySnapshot itself;
}
