import 'package:ario_store/src/entities.dart';

abstract class Collection extends Entity {
  Collection(this.children, String id) : super(id);

  List<Entity> children;

  void appendChild(Entity entity) => children.add(entity);
}

class ARFSCollection extends Collection {
  ARFSCollection(List<Entity> children, String id) : super(children, id);
}
