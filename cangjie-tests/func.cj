/* 
函数高级特性
 - 函数可以作为参数
 - 函数可以作为返回值
 - 函数可以给变量赋值
 - 支持 lambda 表达式
 - 支持嵌套函数
 - 支持闭包
 - 支持命名参数
 - 命名参数支持设置默认值
*/
func node(value: String,
    left!: () -> Unit = {=>}, right!: () -> Unit = {=>}) {
    return { =>
        left()
        print(value)
        right()
    }
}

main() {
    let tree = node('A',
        left: node('B', left: node('C', right: node('D'))),
        right: node('E', left: node('F'), right: node('G')))
    tree() // 期望输出 CDBAFEG
}
