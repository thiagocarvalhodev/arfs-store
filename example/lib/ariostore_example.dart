import 'package:ario_store/ario_store.dart';
import 'package:example/client/ifile.dart';
import 'package:flutter/material.dart';

import 'client/concrete_file_classes.dart';
import 'client/directory.dart';

ArioStore store =
    ArioStore(ArioStoreOptions(gatewayUrl: 'https://arweave.net'));

class ArioStorage extends StatelessWidget {
  ArioStorage({Key? key}) : super(key: key);

  final driveDirectory = Directory('Drives');

  Future<Widget> buildMediaDirectory() async {
    final drives = await store.getPublicDrivesFromOwner(
        'APu-o6jP4A-guGvE1UVUIYGfP1d366e07iWv4ftYhNo');

    for (var drive in drives) {
      final driveSnapshot =
          await store.getEntitySnapshot(drive) as DriveSnapshot;

      final rootFolder = await store.getRootFolder(driveSnapshot);

      driveDirectory.addFile(await addFileHierarchyNode(rootFolder));
    }

    return driveDirectory;
  }

  Future<IFile> addFileHierarchyNode(EntitySnapshot snapshot) async {
    if (snapshot is CollectionSnapshot) {
      final directory = Directory(snapshot.name);

      for (var child in snapshot.children) {
        if (child is FolderSnapshot) {
          directory.addFile(
              await addFileHierarchyNode(await store.getCollection(child)));
        }
        directory.addFile(fileFromSnapshot(child));
      }
      return directory;
    } else {
      final file = fileFromSnapshot(snapshot);

      return file;
    }
  }

  IFile fileFromSnapshot(EntitySnapshot snapshot) {
    if (snapshot is FolderSnapshot) {
      return Directory(snapshot.name);
    } else if (snapshot is FileSnapshot) {
      return TextFile(snapshot.name, snapshot.size);
    }
    throw Exception('Not supported file');
  }

  Future<Entity> addNode(EntitySnapshot entity) async {
    if (entity is FolderSnapshot) {
      final children = await store.getCollection(entity);

      final folderCollection = ARFSCollection([], entity.name);

      for (var child in children.children) {
        folderCollection.appendChild(await addNode(child));
      }
      return folderCollection;
    }

    return entity;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height,
      child: Scaffold(
        appBar: AppBar(),
        body: FutureBuilder<Widget>(
          future: buildMediaDirectory(),
          builder: ((context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              return snapshot.data!;
            } else {
              return Center(
                child: CircularProgressIndicator(),
              );
            }
          }),
        ),
      ),
    );
  }
}
