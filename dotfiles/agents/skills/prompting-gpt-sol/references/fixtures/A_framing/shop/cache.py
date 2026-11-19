from collections import OrderedDict


class LRUCache:
    """Small LRU cache keyed by hashable keys."""

    def __init__(self, capacity=128):
        self.capacity = capacity
        self._data = OrderedDict()

    def get(self, key, default=None):
        if key not in self._data:
            return default
        self._data.move_to_end(key)
        return self._data[key]

    def put(self, key, value):
        self._data[key] = value
        self._data.move_to_end(key)
        if len(self._data) > self.capacity:
            self._data.popitem(last=False)

    def invalidate(self, key):
        self._data.pop(key, None)

    def clear(self):
        self._data.clear()
