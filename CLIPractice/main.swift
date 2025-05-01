//
//  main.swift
//  CLIPractice
//
//  Created by Shin on 3/23/25.
//

import Foundation

// * Create the `Todo` struct.
// * Ensure it has properties: id (UUID), title (String), and isCompleted (Bool).
struct Todo : CustomStringConvertible, Codable {
    var id: UUID
    var title: String
    var isCompleted: Bool

    var description: String {
        let emoji = self.isCompleted ? "\u{2705}" : "\u{274C}"
        return "\(emoji) \(title)"
    }
}

// Create the `Cache` protocol that defines the following method signatures:
//  `func save(todos: [Todo])`: Persists the given todos.
//  `func load() -> [Todo]?`: Retrieves and returns the saved todos, or nil if none exist.
protocol Cache {
    func save(todos: [Todo]) -> Bool
    func load() -> [Todo]?
}

// `FileSystemCache`: This implementation should utilize the file system
// to persist and retrieve the list of todos.
// Utilize Swift's `FileManager` to handle file operations.
final class JSONFileManagerCache: Cache {
    func save(todos: [Todo]) -> Bool {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(todos)
            
            guard let fileURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?
                .appendingPathComponent("todos.txt") else {
                print("Error getting path")
                return false
            }
            
            do {
                try data.write(to: fileURL, options:[.atomic, .completeFileProtection])
                return true
            } catch {
                print(error.localizedDescription)
                return false
            }
        } catch {
            print("Whoops, an error occured: \(error)")
            return false
        }
    }

    func load() -> [Todo]? {
        guard let fileURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?
            .appendingPathComponent("todos.txt") else {
            print("Error getting path")
            return nil
        }
        var todos: [Todo]?
        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            todos = try decoder.decode([Todo].self, from: data)
            return todos
        } catch {
            print("Error reading file: \(error)")
            return nil
        }
    }
}

// `InMemoryCache`: : Keeps todos in an array or similar structure during the session.
// This won't retain todos across different app launches,
// but serves as a quick in-session cache.
final class InMemoryCache: Cache {
    var inMemoryTodos: [Todo]?
    
    init(inMemoryTodos: [Todo]?) {
        self.inMemoryTodos = inMemoryTodos
    }
    
    func save(todos: [Todo]) -> Bool {
        inMemoryTodos = todos
        return true
    }

    func load() -> [Todo]? {
        return inMemoryTodos
    }
}

// The `TodosManager` class should have:
// * A function `func listTodos()` to display all todos.
// * A function named `func addTodo(with title: String)` to insert a new todo.
// * A function named `func toggleCompletion(forTodoAtIndex index: Int)`
//   to alter the completion status of a specific todo using its index.
// * A function named `func deleteTodo(atIndex index: Int)` to remove a todo using its index.
final class TodoManager {
    var todos: [Todo]
    var cache: Cache
    
    init(cache: Cache) {
        self.cache = cache
        todos = cache.load() ?? []
    }

    func listTodos() {
        print("\u{1F4DD} Your Todos:")
        for (index, todo) in todos.enumerated() {
            print("\(index + 1). \(todo.description)")
        }
    }

    func addTodo(with title: String) {
        todos.append(Todo(id: UUID(), title: title, isCompleted: false))
        let saved = cache.save(todos: todos)
        if saved {
            print("\u{1F4CC} Todo added!")
        }
    }

    func toggleCompletion(forTodoAtIndex index: Int) {
        guard todos.indices.contains(index - 1) else {
            print("Invalid index.")
            return
        }
        guard todos[index - 1].isCompleted == false else {
            print("It's already toggled.")
            return
        }
        todos[index - 1].isCompleted = true
        let saved = cache.save(todos: todos)
        if saved {
            print("\u{1F504} Todo completion status toggled!")
        }
    }

    func deleteTodo(atIndex index: Int) {
        guard todos.indices.contains(index - 1) else {
            print("Invalid index.")
            return
        }
        todos.remove(at: index - 1)
        let saved = cache.save(todos: todos)
        if saved {
            print("\u{1F5D1} Todo deleted!")
        }
    }
}


// * The `App` class should have a `func run()` method, this method should perpetually
//   await user input and execute commands.
//  * Implement a `Command` enum to specify user commands. Include cases
//    such as `add`, `list`, `toggle`, `delete`, and `exit`.
//  * The enum should be nested inside the definition of the `App` class
final class App {
    var jsonFileMangerCache: JSONFileManagerCache
    var todoManager: TodoManager
//    var inMemoryCach: InMemoryCache
   
    
    init() {
        self.jsonFileMangerCache = JSONFileManagerCache()
        self.todoManager = TodoManager(cache: jsonFileMangerCache)
//        self.inMemoryCach = InMemoryCache(inMemoryTodos: [])
//        self.todoManager = TodoManager(cache: inMemoryCach)
    }
    
    enum Command: String {
        case add
        case list
        case toggle
        case delete
        case exit
    }
    
    func run() {
        print("\u{1F320} Welcome to Todo CLI! \u{1F320}")
        while true {
            print("What would you like to do? (add, list, toggle, delete, exit):")
            if let input = readLine(), let userCommand = Command(rawValue: input) {
                switch userCommand {
                case .add:
                    print("Enter todo title:")
                    if let titleInput = readLine() {
                        todoManager.addTodo(with: titleInput)
                    } else {
                        print("Please enter a valid title.")
                    }
                case .list:
                    todoManager.listTodos()
                case .toggle:
                    print("Enter the number of the todo to toggle:")
                    if let input = readLine(), let int = Int(input) {
                        todoManager.toggleCompletion(forTodoAtIndex: int)
                    } else {
                        print("Please enter a valid number.")
                    }
                case .delete:
                    print("Enter the number of the todo to delete:")
                    if let input = readLine(), let int = Int(input) {
                        todoManager.deleteTodo(atIndex: int)
                    } else {
                        print("Please enter a valid number.")
                    }
                case .exit:
                    print("\u{1F44B} Thanks for using Todo CLI! See you next time!")
                    return
                }
            } else {
                print("Invalid command. Please enter a valid command.")
            }
        }
    }
}

var app = App()
app.run()


