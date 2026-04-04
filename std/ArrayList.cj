enum Ordering {
    LT
    EQ
    GT
}

class ArrayList<T> {
    var data: Array<T>
    var size: Int64
    var capacity: Int64

    init(capacity) {
        var cap = capacity
        if (cap == nil) { cap = 16 }
        if (cap < 0) { cap = 0 }
        if (cap < 16) { cap = 16 }
        this.capacity = cap
        this.size = 0
        this.data = Array<T>(this.capacity, nil)
    }

    func ensureCapacity(additional: Int64) {
        if (additional <= 0) { return () }
        if (this.capacity - this.size >= additional) { return () }
        var grow = this.capacity + Int64(this.capacity / 2)
        if (grow < this.size + additional) {
            grow = this.size + additional
        }
        this.resize(grow)
    }

    func resize(newCapacity: Int64) {
        if (newCapacity <= this.capacity) { return () }
        let newData = Array<T>(newCapacity, nil)
        for (i in 0..this.size) {
            newData[i] = this.data[i]
        }
        this.data = newData
        this.capacity = newCapacity
    }

    func add(element: T) {
        this.ensureCapacity(1)
        this.data[this.size] = element
        this.size = this.size + 1
    }

    func get(index: Int64): ?T {
        if (index < 0 || index >= this.size) {
            return None
        }
        return Some(this.data[index])
    }

    func isEmpty(): Bool {
        return this.size == 0
    }

    func remove(index: Int64): ?T {
        if (index < 0 || index >= this.size) {
            return None
        }
        let removed = this.data[index]
        var i = index + 1
        while (i < this.size) {
            this.data[i - 1] = this.data[i]
            i = i + 1
        }
        this.size = this.size - 1
        this.data[this.size] = nil
        return Some(removed)
    }

    func removeIf(predicate: (T) -> Bool) {
        var newIndex = 0
        for (i in 0..this.size) {
            let value = this.data[i]
            if (!predicate(value)) {
                this.data[newIndex] = value
                newIndex = newIndex + 1
            }
        }
        for (i in newIndex..this.size) {
            this.data[i] = nil
        }
        this.size = newIndex
    }

    func clear() {
        for (i in 0..this.size) {
            this.data[i] = nil
        }
        this.size = 0
    }

    func clone(): ArrayList<T> {
        let cloned = ArrayList(this.capacity)
        cloned.size = this.size
        for (i in 0..this.size) {
            cloned.data[i] = this.data[i]
        }
        return cloned
    }

    func contains(element: T): Bool {
        for (i in 0..this.size) {
            if (this.data[i] == element) {
                return true
            }
        }
        return false
    }

    func reserve(additional: Int64) {
        this.ensureCapacity(additional)
    }

    func reverse() {
        var left = 0
        var right = this.size - 1
        while (left < right) {
            let tmp = this.data[left]
            this.data[left] = this.data[right]
            this.data[right] = tmp
            left = left + 1
            right = right - 1
        }
    }

    func slice(start: Int64, end: Int64): ArrayList<T> {
        let result = ArrayList()
        var i = start
        while (i <= end && i < this.size) {
            if (i >= 0) {
                result.add(this.data[i])
            }
            i = i + 1
        }
        return result
    }

    func toArray(): Array<T> {
        return Array<T>(this.size, { i: Int64 => this.data[i] })
    }

    func iterator() {
        var index = 0
        return { =>
            if (index < this.size) {
                let value = this.data[index]
                index = index + 1
                return Some(value)
            }
            return None
        }
    }

    func sortBy(comparator: (T, T) -> Ordering) {
        var i = 1
        while (i < this.size) {
            let key = this.data[i]
            var j = i - 1
            while (j >= 0 && comparator(this.data[j], key) == Ordering.GT) {
                this.data[j + 1] = this.data[j]
                j = j - 1
            }
            this.data[j + 1] = key
            i = i + 1
        }
    }

    func toString(): String {
        var out = "["
        var i = 0
        while (i < this.size) {
            if (i > 0) {
                out = out .. ", "
            }
            out = out .. tostring(this.data[i])
            i = i + 1
        }
        return out .. "]"
    }
}
