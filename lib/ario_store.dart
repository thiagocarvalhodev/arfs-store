library ario_store;

import 'ario_store.dart';

export 'src/ario_store.dart';
export 'entities.dart';

final arioStorage =
    ArioStore(ArioStoreOptions(gatewayUrl: 'https://arweave.net'));
void main() async {
  // getRootFolder();
  getRootFolderCollection();
}

/// Usage examples
Future<void> getRootFolder() async {
  final drives = await arioStorage
      .getPublicDrivesFromOwner('APu-o6jP4A-guGvE1UVUIYGfP1d366e07iWv4ftYhNo');

  for (var drive in drives) {
    final driveSnapshot = await arioStorage.getEntitySnapshot(drive);

    final collection =
        await arioStorage.getRootFolder(driveSnapshot as DriveSnapshot);

    print(collection.name);
    for (var child in collection.children) {
      if (child is FolderSnapshot) {
        print('┣ ${child.name}');
        final folderChildren = await arioStorage.getCollection(
            FolderSnapshot(name: child.name, metadata: child.metadata));
        for (var child in folderChildren.children) {
          print('┃  ┣  ${child.name}');
        }
      }
    }
  }
}

/// Mount a Drive tree structure
void getRootFolderCollection() async {
  final drives = await arioStorage
      .getPublicDrivesFromOwner('APu-o6jP4A-guGvE1UVUIYGfP1d366e07iWv4ftYhNo');

  for (var drive in drives) {
    final driveSnapshot = await arioStorage.getEntitySnapshot(drive);
    final driveCollection = ARFSCollection([], driveSnapshot.name);

    final collection =
        await arioStorage.getRootFolder(driveSnapshot as DriveSnapshot);

    for (var element in collection.children) {
      driveCollection.appendChild(await addNode(element));
    }
    print(driveCollection.name);

    driveCollection.children.forEach((child) {
      printHierachy(child, 1);
    });
  }
}

/// Adds a node to collection hierachy
Future<Entity> addNode(EntitySnapshot entity) async {
  if (entity is FolderSnapshot) {
    final children = await arioStorage.getCollection(entity);

    final folderCollection = ARFSCollection([], entity.name);

    for (var child in children.children) {
      folderCollection.appendChild(await addNode(child));
    }
    return folderCollection;
  }
  return entity;
}

// Prints a hierachy of a entity.
void printHierachy(Entity entity, int level) {
  if (entity is Collection) {
    print('┃${'--' * (level)} Folder: ' + entity.name);
    ++level;
    for (var child in entity.children) {
      printHierachy(child, level);
    }
  } else {
    print('┃' + '--' * level + '┣ File: ' + entity.name);
  }
}
