dofile("cangjie-tests/_testing.cj")

// Usage: Builder pattern using classes, method chaining, and Option

open class QueryBuilder {
    var tableName: String = ""
    var conditions: Array<String> = []
    var condCount: Int64 = 0
    var orderField: ?String = None
    var limitVal: ?Int64 = None

    func init(table: String) {
        this.tableName = table
        this.conditions = []
        this.condCount = 0
    }

    func where(cond: String): QueryBuilder {
        this.conditions[this.condCount] = cond
        this.condCount = this.condCount + 1
        return this
    }

    func orderBy(field: String): QueryBuilder {
        this.orderField = Some(field)
        return this
    }

    func limit(n: Int64): QueryBuilder {
        this.limitVal = Some(n)
        return this
    }

    func build(): String {
        var query = "SELECT * FROM ${this.tableName}"
        if (this.condCount > 0) {
            var whereParts = this.conditions[0]
            var i: Int64 = 1
            while (i < this.condCount) {
                whereParts = "${whereParts} AND ${this.conditions[i]}"
                i = i + 1
            }
            query = "${query} WHERE ${whereParts}"
        }
        if (this.orderField.isSome()) {
            query = "${query} ORDER BY ${this.orderField.getOrThrow()}"
        }
        if (this.limitVal.isSome()) {
            query = "${query} LIMIT ${this.limitVal.getOrThrow()}"
        }
        return query
    }
}

// --- Section: Simple query ---
let q1 = QueryBuilder("users").build()
expectEq(q1, "SELECT * FROM users", "simple query")

// --- Section: Query with conditions ---
let q2 = QueryBuilder("orders")
    .where("status = 'active'")
    .where("amount > 100")
    .build()
expectEq(q2, "SELECT * FROM orders WHERE status = 'active' AND amount > 100",
    "query with conditions")

// --- Section: Full query with all clauses ---
let q3 = QueryBuilder("products")
    .where("category = 'electronics'")
    .orderBy("price")
    .limit(10)
    .build()
expectEq(q3, "SELECT * FROM products WHERE category = 'electronics' ORDER BY price LIMIT 10",
    "full query")

// --- Section: Query without conditions but with order and limit ---
let q4 = QueryBuilder("logs")
    .orderBy("created_at")
    .limit(50)
    .build()
expectEq(q4, "SELECT * FROM logs ORDER BY created_at LIMIT 50",
    "query with order and limit only")

// --- Section: Data transformation pipeline ---
func pipeline(data: Array<Int64>): Array<Int64> {
    var result: Array<Int64> = []
    var size: Int64 = 0
    var i: Int64 = 0
    let n = data.size
    // Filter: keep only positive
    while (i < n) {
        if (data[i] > 0) {
            result[size] = data[i]
            size = size + 1
        }
        i = i + 1
    }
    // Transform: double each
    i = 0
    while (i < size) {
        result[i] = result[i] * 2
        i = i + 1
    }
    result.size = size
    return result
}

let input = [3, -1, 5, 0, -2, 7]
let output = pipeline(input)
expectEq(output.size, 3, "pipeline output size")
expectEq(output[0], 6, "pipeline output[0]")
expectEq(output[1], 10, "pipeline output[1]")
expectEq(output[2], 14, "pipeline output[2]")

if (!__test_failed) {
    println("PASS: builder_pipeline_pattern")
}
