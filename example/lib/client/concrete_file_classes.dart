import 'package:example/client/file.dart';
import 'package:flutter/material.dart';

class AudioFile extends File {
  const AudioFile(String title, int size)
      : super(title, size, Icons.music_note);
}

class ImageFile extends File {
  const ImageFile(String title, int size) : super(title, size, Icons.image);
}

class TextFile extends File {
  const TextFile(String title, int size)
      : super(title, size, Icons.description);
}

class VideoFile extends File {
  const VideoFile(String title, int size) : super(title, size, Icons.movie);
}
