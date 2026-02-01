import Foundation

// MARK: - 1.
struct Task {
    let id: UUID
    private(set) var title: String
    private(set) var isCompleted: Bool
    
    init(title: String) {
        self.id = UUID()
        self.title = title
        self.isCompleted = false
    }
    
    mutating func complete() {
        isCompleted = true
    }
}

// MARK: -

protocol Identifiable {
    associatedtype ID: Equatable
    var id: ID { get }
}

extension Task: Identifiable {}

//

enum AppState {
    case idle
    case loading
    case loaded
    case error(reason: String)
}

// MARK: - 3. Ошибки

enum TaskError: Error {
    case taskNotFound
    case emptyList
    case invalidData
    case storageError
}

extension TaskError: CustomStringConvertible {
    var description: String {
        switch self {
        case .taskNotFound:
            return "Задача не найдена"
        case .emptyList:
            return "Список задач пуст"
        case .invalidData:
            return "Неверные данные"
        case .storageError:
            return "Ошибка хранилища"
        }
    }
}

// MARK: - 4. Протокол хранилища

protocol Storage {
    associatedtype Item
    
    mutating func add(_ item: Item) throws
    mutating func remove(by id: UUID) throws
    func fetchAll() throws -> [Item]
}

// MARK: - 6. Protocol Extension с where

extension Storage where Item: Identifiable, Item.ID == UUID {
    func find(by id: UUID) throws -> Item {
        let items = try fetchAll()
        guard let item = items.first(where: { $0.id == id }) else {
            throw TaskError.taskNotFound
        }
        return item
    }
}

// Дополнительное расширение для поиска по условию
extension Storage {
    func find(where predicate: (Item) -> Bool) throws -> Item {
        let items = try fetchAll()
        guard let item = items.first(where: predicate) else {
            throw TaskError.taskNotFound
        }
        return item
    }
}

// MARK: - 5.

struct InMemoryStorage<T>: Storage where T: Identifiable, T.ID == UUID {
    typealias Item = T
    
    private var items: [T] = []
    
    mutating func add(_ item: T) throws {
        items.append(item)
    }
    
    mutating func remove(by id: UUID) throws {
        guard let index = items.firstIndex(where: { $0.id == id }) else {
            throw TaskError.taskNotFound
        }
        items.remove(at: index)
    }
    
    func fetchAll() throws -> [T] {
        guard !items.isEmpty else {
            throw TaskError.emptyList
        }
        return items
    }
    
    // Метод для получения всех элементов без выброса ошибки
    func fetchAllOrEmpty() -> [T] {
        return items
    }
}

// MARK: - 7. Сервис работы с задачами

final class TaskService<S: Storage> where S.Item == Task {
    private var storage: S
    private(set) var state: AppState = .idle
    
    init(storage: S) {
        self.storage = storage
    }
    
    func addTask(title: String) throws {
        state = .loading
        
        guard !title.trimmingCharacters(in: .whitespaces).isEmpty else {
            state = .error(reason: "Название задачи не может быть пустым")
            throw TaskError.invalidData
        }
        
        let task = Task(title: title)
        try storage.add(task)
        
        state = .loaded
        log("Задача добавлена: \(title)")
    }
    
    func getAllTasks() throws -> [Task] {
        state = .loading
        let tasks = try storage.fetchAll()
        state = .loaded
        return tasks
    }
    
    func completeTask(by id: UUID) throws {
        state = .loading
        
        var task = try storage.find(by: id)
        
        guard !task.isCompleted else {
            state = .error(reason: "Задача уже выполнена")
            throw TaskError.invalidData
        }
        
        task.complete()
        try storage.remove(by: id)
        try storage.add(task)
        
        state = .loaded
        log("Задача выполнена: \(task.title)")
    }
    
    func removeTask(by id: UUID) throws {
        state = .loading
        try storage.remove(by: id)
        state = .loaded
        log("Задача удалена")
    }
    
    func getTasksSorted(by sortType: TaskSortType) throws -> [Task] {
        let tasks = try getAllTasks()
        return sortType.sort(tasks)
    }
    
    private func log(_ message: String) {
        print("[LOG] \(message)")
    }
}

// MARK: -

enum TaskSortType {
    case byTitle
    case byStatus
    case byCreation
    
    func sort(_ tasks: [Task]) -> [Task] {
        switch self {
        case .byTitle:
            return tasks.sorted { $0.title < $1.title }
        case .byStatus:
            return tasks.sorted { !$0.isCompleted && $1.isCompleted }
        case .byCreation:
            return tasks
        }
    }
}

// MARK: -

enum UserCommand {
    case add
    case list
    case complete
    case remove
    case sort
    case help
    case exit
    case unknown
    
    static func parse(_ input: String) -> UserCommand {
        switch input.lowercased().trimmingCharacters(in: .whitespaces) {
        case "1", "add", "добавить":
            return .add
        case "2", "list", "список":
            return .list
        case "3", "complete", "выполнить":
            return .complete
        case "4", "remove", "удалить":
            return .remove
        case "5", "sort", "сортировка":
            return .sort
        case "help", "помощь":
            return .help
        case "exit", "quit", "выход":
            return .exit
        default:
            return .unknown
        }
    }
}

// MARK: - 9.

final class ConsoleApp {
    private let taskService: TaskService<InMemoryStorage<Task>>
    private var isRunning = true
    
    init() {
        let storage = InMemoryStorage<Task>()
        self.taskService = TaskService(storage: storage)
    }
    
    func run() {
        printWelcome()
        
        while isRunning {
            printMenu()
            
            guard let input = readLine() else {
                continue
            }
            
            let command = UserCommand.parse(input)
            handleCommand(command)
        }
        
        printGoodbye()
    }
    
    private func printWelcome() {
        print("\n╔════════════════════════════════════════╗")
        print("║   Менеджер задач - Task Manager       ║")
        print("╚════════════════════════════════════════╝\n")
    }
    
    private func printMenu() {
        print("\n--- Меню ---")
        print("1. Добавить задачу")
        print("2. Показать все задачи")
        print("3. Отметить задачу как выполненную")
        print("4. Удалить задачу")
        print("5. Сортировать задачи")
        print("help - Помощь")
        print("exit - Выход")
        print("\nВведите команду: ", terminator: "")
    }
    
    private func handleCommand(_ command: UserCommand) {
        do {
            switch command {
            case .add:
                try handleAddTask()
            case .list:
                try handleListTasks()
            case .complete:
                try handleCompleteTask()
            case .remove:
                try handleRemoveTask()
            case .sort:
                try handleSortTasks()
            case .help:
                printHelp()
            case .exit:
                isRunning = false
            case .unknown:
                print("❌ Неизвестная команда. Введите 'help' для помощи.")
            }
        } catch let error as TaskError {
            handleError(error)
        } catch {
            print("❌ Неожиданная ошибка: \(error)")
        }
    }
    
    private func handleAddTask() throws {
        print("\nВведите название задачи: ", terminator: "")
        guard let title = readLine() else {
            throw TaskError.invalidData
        }
        
        try taskService.addTask(title: title)
        print("✅ Задача успешно добавлена!")
    }
    
    private func handleListTasks() throws {
        let tasks = try taskService.getAllTasks()
        
        print("\n📋 Список задач:")
        print("─────────────────────────────────────────")
        
        for (index, task) in tasks.enumerated() {
            let status = task.isCompleted ? "✅" : "⭕️"
            let taskNumber = String(format: "%2d", index + 1)
            print("\(taskNumber). \(status) \(task.title)")
            print("    ID: \(task.id.uuidString.prefix(8))...")
        }
        
        print("─────────────────────────────────────────")
        print("Всего задач: \(tasks.count)")
    }
    
    private func handleCompleteTask() throws {
        try handleListTasks()
        
        print("\nВведите ID задачи (первые символы): ", terminator: "")
        guard let input = readLine(), !input.isEmpty else {
            throw TaskError.invalidData
        }
        
        let tasks = try taskService.getAllTasks()
        guard let task = tasks.first(where: {
            $0.id.uuidString.lowercased().hasPrefix(input.lowercased())
        }) else {
            throw TaskError.taskNotFound
        }
        
        try taskService.completeTask(by: task.id)
        print("✅ Задача отмечена как выполненная!")
    }
    
    private func handleRemoveTask() throws {
        try handleListTasks()
        
        print("\nВведите ID задачи (первые символы): ", terminator: "")
        guard let input = readLine(), !input.isEmpty else {
            throw TaskError.invalidData
        }
        
        let tasks = try taskService.getAllTasks()
        guard let task = tasks.first(where: {
            $0.id.uuidString.lowercased().hasPrefix(input.lowercased())
        }) else {
            throw TaskError.taskNotFound
        }
        
        try taskService.removeTask(by: task.id)
        print("✅ Задача удалена!")
    }
    
    private func handleSortTasks() throws {
        print("\nВыберите тип сортировки:")
        print("1. По названию")
        print("2. По статусу (сначала невыполненные)")
        print("3. По порядку создания")
        print("\nВведите номер: ", terminator: "")
        
        guard let input = readLine() else {
            throw TaskError.invalidData
        }
        
        let sortType: TaskSortType
        switch input {
        case "1":
            sortType = .byTitle
        case "2":
            sortType = .byStatus
        case "3":
            sortType = .byCreation
        default:
            throw TaskError.invalidData
        }
        
        let tasks = try taskService.getTasksSorted(by: sortType)
        
        print("\n📋 Отсортированный список задач:")
        print("─────────────────────────────────────────")
        
        for (index, task) in tasks.enumerated() {
            let status = task.isCompleted ? "✅" : "⭕️"
            let taskNumber = String(format: "%2d", index + 1)
            print("\(taskNumber). \(status) \(task.title)")
        }
        
        print("─────────────────────────────────────────")
    }
    
    private func printHelp() {
        print("\n📖 Справка:")
        print("─────────────────────────────────────────")
        print("Доступные команды:")
        print("  1 / add      - Добавить новую задачу")
        print("  2 / list     - Показать все задачи")
        print("  3 / complete - Отметить задачу как выполненную")
        print("  4 / remove   - Удалить задачу")
        print("  5 / sort     - Сортировать задачи")
        print("  help         - Показать эту справку")
        print("  exit         - Выйти из приложения")
        print("─────────────────────────────────────────")
    }
    
    private func printGoodbye() {
        print("\n👋 До свидания! Спасибо за использование Task Manager!")
    }
    
    private func handleError(_ error: TaskError) {
        switch taskService.state {
        case .error(let reason):
            print("❌ Ошибка: \(reason)")
        default:
            print("❌ Ошибка: \(error.description)")
        }
    }
}

// MARK: -

let app = ConsoleApp()
app.run()
