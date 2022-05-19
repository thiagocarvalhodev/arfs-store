import 'package:example/client/ifile.dart';
import 'package:flutter/material.dart';

import 'helpers/file_size_converter.dart';

class Directory extends StatelessWidget implements IFile {
  Directory(this.title, [this.isInitiallyExpanded = false]);

  final String title;
  final bool isInitiallyExpanded;

  final List<IFile> files = [];

  @override
  Widget build(BuildContext context) {
    return render(context);
  }

  void addFile(IFile file) {
    files.add(file);
  }

  @override
  int getSize() {
    var sum = 0;
    files.forEach((IFile file) => sum += file.getSize());
    return sum;
  }

  @override
  Widget render(BuildContext context) {
    return Theme(
      data: ThemeData(
        accentColor: Colors.black,
      ),
      child: Padding(
        padding: const EdgeInsets.only(left: 16),
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: 100, maxWidth: 10000),
              child: ExpansionTile(
                leading: Icon(Icons.folder),
                maintainState: true,
                title: Text(
                    "$title (${FileSizeConverter.bytesToString(getSize())})"),
                children:
                    files.map((IFile file) => file.render(context)).toList(),
                initiallyExpanded: isInitiallyExpanded,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
