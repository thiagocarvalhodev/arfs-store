abstract class EntityMetadata {
  EntityMetadata({
    required this.id,
    required this.transactionId,
    required this.arFS,
    required this.contentType,
    required this.unixTime,
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
      required String transactionId})
      : super(
            id: id,
            arFS: arFS,
            contentType: contentType,
            unixTime: unixTime,
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
      this.parentFolderId})
      : super(
            id: id,
            arFS: arFS,
            contentType: contentType,
            unixTime: unixTime,
            transactionId: transactionId);

  String? parentFolderId;
  String driveId;
}

class FileMetadata extends EntityMetadata {
  FileMetadata(
      {required String id,
      required String transactionId,
      required String arFS,
      required String contentType,
      required DateTime unixTime,
      required this.driveId,
      this.parentFolderId})
      : super(
            id: id,
            transactionId: transactionId,
            arFS: arFS,
            contentType: contentType,
            unixTime: unixTime);
  String? parentFolderId;
  String driveId;
}
