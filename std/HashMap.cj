dofile("std/ArrayList.cj")

class HashMap<K, V> {
    var data = {}
    var size: Int64
    var capacity: Int64

    init(capacity) {
        var cap = capacity
        if (cap == nil) { cap = 16 }
        if (cap < 0) { cap = 0 }
        if (cap < 16) { cap = 16 }
        this.size = 0
        this.capacity = cap
        this.data = {}
    }

    func ensureCapacity(additional: Int64) {
        if (additional <= 0) { return () }
        if (this.capacity - this.size >= additional) { return () }
        var grow = this.capacity + Int64(this.capacity / 2)
        if (grow < this.size + additional) {
            grow = this.size + additional
        }
        this.capacity = grow
    }

    func add(key: K, value: V): ?V {
        this.ensureCapacity(1)
        let oldValue = this.data[key]
        if (oldValue != nil) {
            this.data[key] = value
            return Some(oldValue)
        }
        this.data[key] = value
        this.size = this.size + 1
        return None
    }

    func get(key: K): ?V {
        let value = this.data[key]
        if (value == nil) {
            return None
        }
        return Some(value)
    }

    func replace(key: K, value: V): ?V {
        let current = this.data[key]
        if (current == nil) {
            return None
        }
        this.data[key] = value
        return Some(current)
    }

    func remove(key: K): ?V {
        let current = this.data[key]
        if (current == nil) {
            return None
        }
        this.data[key] = nil
        this.size = this.size - 1
        return Some(current)
    }

    func removeIf(predicate: (K, V) -> Bool) {
        for (k, v in pairs(this.data)) {
            if (predicate(k, v)) {
                this.data[k] = nil
                this.size = this.size - 1
            }
        }
    }

    func clear() {
        this.data = {}
        this.size = 0
    }

    func clone(): HashMap<K, V> {
        let cloned = HashMap(this.capacity)
        for (k, v in pairs(this.data)) {
            cloned.data[k] = v
            cloned.size = cloned.size + 1
        }
        return cloned
    }

    func contains(key: K): Bool {
        return this.data[key] != nil
    }

    func reserve(additional: Int64) {
        this.ensureCapacity(additional)
    }

    func keys(): ArrayList<K> {
        let result = ArrayList()
        result.reserve(this.size)
        for (k, _ in pairs(this.data)) {
            result.add(k)
        }
        return result
    }

    func values(): ArrayList<V> {
        let result = ArrayList()
        result.reserve(this.size)
        for (_, v in pairs(this.data)) {
            result.add(v)
        }
        return result
    }

    func toArray(): Array<(K, V)> {
        let result = Array<(K, V)>(this.size, nil)
        var index = 0
        for (k, v in pairs(this.data)) {
            result[index] = (k, v)
            index = index + 1
        }
        return result
    }

    func iterator() {
        let entries = this.toArray()
        var index = 0
        return { =>
            if (index < entries.size) {
                let value = entries[index]
                index = index + 1
                return Some(value)
            }
            return None
        }
    }

    func isEmpty(): Bool {
        return this.size == 0
    }

    func toString(): String {
        let entries = this.toArray()
        var out = "["
        var i = 0
        while (i < entries.size) {
            if (i > 0) {
                out = out .. ", "
            }
            let entry = entries[i]
            out = out .. "(${tostring(entry[0])}, ${tostring(entry[1])})"
            i = i + 1
        }
        return out .. "]"
    }
}
