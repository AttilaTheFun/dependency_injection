
public protocol FooService {
    func foo() async throws -> String
}

public protocol FooServiceProvider {
    var fooService: any FooService { get }
}