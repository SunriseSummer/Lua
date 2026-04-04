class ArrayStack<T> {
    var data: Array<T>
    var size: Int64
    var capacity: Int64

    init(capacity) {
        var cap = capacity
        if (cap == nil) { cap = 8 }
        if (cap < 0) { cap = 0 }
        if (cap < 8) { cap = 8 }
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

    func isEmpty(): Bool {
        return this.size == 0
    }

    func remove(): ?T {
        if (this.size == 0) {
            return None
        }
        this.size = this.size - 1
        let value = this.data[this.size]
        this.data[this.size] = nil
        return Some(value)
    }

    func clear() {
        for (i in 0..this.size) {
            this.data[i] = nil
        }
        this.size = 0
    }

    func clone(): ArrayStack<T> {
        let cloned = ArrayStack(this.capacity)
        cloned.size = this.size
        for (i in 0..this.size) {
            cloned.data[i] = this.data[i]
        }
        return cloned
    }

    func reserve(additional: Int64) {
        this.ensureCapacity(additional)
    }

    func toArray(): Array<T> {
        return Array<T>(this.size, { i: Int64 => this.data[this.size - 1 - i] })
    }

    func iterator() {
        var index = this.size - 1
        return { =>
            if (index >= 0) {
                let value = this.data[index]
                index = index - 1
                return Some(value)
            }
            return None
        }
    }

    func toString(): String {
        var out = "["
        var i = this.size - 1
        var first = true
        while (i >= 0) {
            if (!first) {
                out = out .. ", "
            }
            first = false
            out = out .. tostring(this.data[i])
            i = i - 1
        }
        return out .. "]"
    }
}
