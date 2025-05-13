import 'package:flutter/material.dart';
import '../models/drawing_point.dart';

class DrawingProvider with ChangeNotifier {
    List<List<DrawingPoint>> _history = [];
    int _historyIndex = -1;

    List<List<DrawingPoint>> get currentPath => 
        _history.sublist(0, _historyIndex + 1);

    void addPath(List<DrawingPoint> path) {
        if (_historyIndex < _history.length - 1) {
            _history = _history.sublist(0, _historyIndex + 1);
        }
        _history.add(path);
        _historyIndex++;
        notifyListeners();
    }

    void undo() {
        if (_historyIndex > 0) {
            _historyIndex--;
            notifyListeners();
        }
    }

    void redo() {
        if (_historyIndex < _history.length - 1) {
            _historyIndex++;
            notifyListeners();
        }
    }

    void clear() {
        _history.clear();
        _historyIndex = -1;
        notifyListeners();
    }
}