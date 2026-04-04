dofile("std/HashMap.cj")

class HashSet<T> {
    var map: HashMap<T, Bool>
    var size: Int64
    var capacity: Int64

    init(capacity) {
        this.map = HashMap(capacity)
        this.size = this.map.size
        this.capacity = this.map.capacity
    }

    func add(element: T): Bool {
        if (this.map.contains(element)) {
            return false
        }
        this.map.add(element, true)
        this.size = this.map.size
        this.capacity = this.map.capacity
        return true
    }

    func isEmpty(): Bool {
        return this.size == 0
    }

    func remove(element: T): Bool {
        let removed = this.map.remove(element)
        if (removed == None) {
            return false
        }
        this.size = this.map.size
        return true
    }

    func removeIf(predicate: (T) -> Bool) {
        this.map.removeIf({ k, _ => predicate(k) })
        this.size = this.map.size
    }

    func clear() {
        this.map.clear()
        this.size = 0
    }

    func clone(): HashSet<T> {
        let cloned = HashSet(this.capacity)
        cloned.map = this.map.clone()
        cloned.size = cloned.map.size
        cloned.capacity = cloned.map.capacity
        return cloned
    }

    func contains(element: T): Bool {
        return this.map.contains(element)
    }

    func reserve(additional: Int64) {
        this.map.reserve(additional)
        this.capacity = this.map.capacity
    }

    func retain(all) {
        let keys = this.map.keys().toArray()
        for (k in keys) {
            if (!all.contains(k)) {
                this.map.remove(k)
            }
        }
        this.size = this.map.size
    }

    func subsetOf(other): Bool {
        let keys = this.map.keys().toArray()
        for (k in keys) {
            if (!other.contains(k)) {
                return false
            }
        }
        return true
    }

    func toArray(): Array<T> {
        return this.map.keys().toArray()
    }

    func iterator() {
        let values = this.toArray()
        var index = 0
        return { =>
            if (index < values.size) {
                let value = values[index]
                index = index + 1
                return Some(value)
            }
            return None
        }
    }

    func toString(): String {
        let values = this.toArray()
        var out = "["
        var i = 0
        while (i < values.size) {
            if (i > 0) {
                out = out .. ", "
            }
            out = out .. tostring(values[i])
            i = i + 1
        }
        return out .. "]"
    }
}
