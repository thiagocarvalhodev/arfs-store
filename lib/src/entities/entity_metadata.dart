abstract class EntityMetadata {
  EntityMetadata({
    required this.id,
    required this.transactionId,
    required this.arFS,
    required this.contentType,
    required this.unixTime,
    this.entityType,
  });

  String id;
  String transactionId;
  EntityType? entityType;
  DateTime unixTime;
  String? cipher;
  String? cipherIV;
  String arFS;
  String contentType;
}

enum EntityType { folder, file, drive, manifest }

class DriveMetadata extends EntityMetadata {
  DriveMetadata(
      {required String id,
      required String arFS,
      required String contentType,
      required DateTime unixTime,
      required String transactionId,
      required EntityType entityType})
      : super(
            id: id,
            arFS: arFS,
            contentType: contentType,
            unixTime: unixTime,
            entityType: entityType,
            transactionId: transactionId);
}

class FolderMetadata extends EntityMetadata {
  FolderMetadata(
      {required String id,
      required String arFS,
      required String contentType,
      required DateTime unixTime,
      required this.driveId,
      required String transactionId,
      required EntityType entityType,
      this.parentFolderId})
      : super(
            id: id,
            arFS: arFS,
            contentType: contentType,
            unixTime: unixTime,
            entityType: entityType,
            transactionId: transactionId);

  String? parentFolderId;
  String driveId;
}

class FileMetadata extends EntityMetadata {
  FileMetadata(
      {this.parentFolderId,
      required this.driveId,
      required String id,
      required String transactionId,
      required String arFS,
      required String contentType,
      required DateTime unixTime,
      required EntityType entityType})
      : super(
            id: id,
            transactionId: transactionId,
            arFS: arFS,
            entityType: entityType,
            contentType: contentType,
            unixTime: unixTime);
  String? parentFolderId;
  String driveId;
}
